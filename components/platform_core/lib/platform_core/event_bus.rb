module PlatformCore
  # A small, inspectable pub/sub layer. Modules NEVER call each other's code
  # directly across a boundary -- they publish events and subscribe to them.
  #
  #   PlatformCore::EventBus.subscribe("feed.post_created", Feed::NotifyFollowers)
  #   PlatformCore::EventBus.publish("feed.post_created", post_id: 42)
  #
  # Subscribers respond to .call(event_name, payload). Pass async: true to run
  # them through ActiveJob/Sidekiq instead of inline. The registry is public so
  # the wiring of the whole system can be introspected at runtime (e.g. for an
  # agent-callable capability map).
  #
  # Publishing is decoupled by contract: a published event is a signal, not a
  # method call. A subscriber that raises -- including an async handler whose job
  # backend (Redis) is unreachable at enqueue time -- must NEVER break the
  # publisher's own write. Such failures are reported to Sentry and the log, and
  # the remaining subscribers still run. (A missing/unreachable Sidekiq is an
  # infrastructure gap: the async side effect is simply lost until it is fixed,
  # but the domain write it reacted to stands.)
  module EventBus
    Subscription = Struct.new(:handler, :async, keyword_init: true)

    class << self
      def subscribe(event_name, handler, async: false)
        registry[event_name.to_s] << Subscription.new(handler: handler, async: async)
      end

      def publish(event_name, **payload)
        event_name = event_name.to_s
        PlatformCore::Analytics.capture_domain_event(event_name, payload) if defined?(PlatformCore::Analytics)

        registry[event_name].each { |sub| deliver(event_name, sub, payload) }
      end

      # Full map of event_name => [handlers]. Useful for debugging and for
      # exposing the system's capabilities to tooling.
      def registry
        @registry ||= Hash.new { |h, k| h[k] = [] }
      end

      def reset!
        @registry = nil
      end

      private

      def deliver(event_name, sub, payload)
        if sub.async
          EventBus::AsyncDispatch.perform_later(event_name, sub.handler.to_s, payload)
        else
          sub.handler.call(event_name, payload)
        end
      rescue StandardError => e
        report_delivery_failure(event_name, sub, e)
      end

      def report_delivery_failure(event_name, sub, error)
        Sentry.capture_exception(error) if defined?(Sentry) && Sentry.initialized?
        Rails.logger.error(
          "event=event_bus_delivery_failed domain_event=#{event_name.inspect} " \
          "handler=#{sub.handler} async=#{sub.async} " \
          "error_class=#{error.class.name} error=#{error.message.inspect}"
        )
      end
    end

    class AsyncDispatch < ActiveJob::Base
      queue_as :default
      def perform(event_name, handler_name, payload)
        handler_name.constantize.call(event_name, payload.symbolize_keys)
      end
    end
  end
end
