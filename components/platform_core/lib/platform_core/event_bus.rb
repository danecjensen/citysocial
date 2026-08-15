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
  module EventBus
    Subscription = Struct.new(:handler, :async, keyword_init: true)

    class << self
      def subscribe(event_name, handler, async: false)
        registry[event_name.to_s] << Subscription.new(handler: handler, async: async)
      end

      def publish(event_name, **payload)
        PlatformCore::Analytics.capture_domain_event(event_name, payload) if defined?(PlatformCore::Analytics)

        registry[event_name.to_s].each do |sub|
          if sub.async
            EventBus::AsyncDispatch.perform_later(event_name.to_s, sub.handler.to_s, payload)
          else
            sub.handler.call(event_name.to_s, payload)
          end
        end
      end

      # Full map of event_name => [handlers]. Useful for debugging and for
      # exposing the system's capabilities to tooling.
      def registry
        @registry ||= Hash.new { |h, k| h[k] = [] }
      end

      def reset!
        @registry = nil
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
