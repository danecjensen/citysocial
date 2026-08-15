require "sentry/rails/log_subscribers/action_mailer_subscriber"
require "sentry/rails/log_subscribers/active_job_subscriber"

module CitySocial
  module SentryConfig
    module_function

    def sample_rate(name, default)
      value = Float(ENV.fetch(name, default.to_s))
      return value if value.between?(0.0, 1.0)

      raise ArgumentError, "#{name} must be between 0.0 and 1.0"
    rescue ArgumentError, TypeError
      raise ArgumentError, "#{name} must be a number between 0.0 and 1.0"
    end

    def boolean(name, default)
      ActiveModel::Type::Boolean.new.cast(ENV.fetch(name, default.to_s))
    end

    def list(name, default = "")
      ENV.fetch(name, default).split(",").map(&:strip).reject(&:empty?)
    end

    def scrub_sidekiq_arguments(event, _hint = nil)
      key = event.contexts.key?(:sidekiq) ? :sidekiq : "sidekiq"
      context = event.contexts[key]
      return event unless context.is_a?(Hash)

      context = context.dup
      context[context.key?(:args) ? :args : "args"] = "[Filtered]" if context.key?(:args) || context.key?("args")
      event.contexts[key] = context
      event
    end
  end
end

request_sample_rate = CitySocial::SentryConfig.sample_rate("SENTRY_TRACES_SAMPLE_RATE", 0.1)
api_sample_rate = CitySocial::SentryConfig.sample_rate("SENTRY_API_TRACES_SAMPLE_RATE", 0.25)
job_sample_rate = CitySocial::SentryConfig.sample_rate("SENTRY_JOB_TRACES_SAMPLE_RATE", 0.05)
profile_sample_rate = CitySocial::SentryConfig.sample_rate("SENTRY_PROFILES_SAMPLE_RATE", 0.1)

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.environment = ENV.fetch("SENTRY_ENVIRONMENT", Rails.env)
  config.enabled_environments = CitySocial::SentryConfig.list("SENTRY_ENABLED_ENVIRONMENTS", "production")
  config.release = ENV["SENTRY_RELEASE"] if ENV["SENTRY_RELEASE"].present?
  config.org_id = ENV["SENTRY_ORG_ID"] if ENV["SENTRY_ORG_ID"].present?
  config.debug = CitySocial::SentryConfig.boolean("SENTRY_DEBUG", false)

  # Data minimization is deliberate. Resident identity is added by ID in the
  # controller layer, while IPs, cookies, query strings, form bodies, Sidekiq
  # arguments, SQL binds, email addresses, and frame locals stay out.
  config.send_default_pii = false
  config.include_local_variables = false
  config.send_modules = true
  config.before_send = CitySocial::SentryConfig.method(:scrub_sidekiq_arguments)
  config.before_send_transaction = CitySocial::SentryConfig.method(:scrub_sidekiq_arguments)

  # Errors are never sampled. Only performance telemetry is sampled, with API
  # ingestion favored over ordinary requests and high-volume jobs sampled less.
  # A parent decision is honored so a distributed trace stays complete.
  config.traces_sampler = lambda do |sampling_context|
    parent_sampled = sampling_context[:parent_sampled]
    next parent_sampled unless parent_sampled.nil?

    path = sampling_context.dig(:env, "PATH_INFO").to_s
    operation = sampling_context.dig(:transaction_context, :op).to_s

    next 0.0 if %w[/up /health].include?(path)
    next api_sample_rate if path.start_with?("/api/")
    next job_sample_rate if operation == "queue.process"

    request_sample_rate
  end
  config.profiles_sample_rate = profile_sample_rate
  config.profiler_class = Sentry::Vernier::Profiler
  config.enable_backpressure_handling = true
  config.capture_queue_time = true

  # Only explicitly trusted downstream services receive trace headers. The
  # app is currently a monolith, so the secure default is no HTTP propagation.
  config.strict_trace_continuation = true
  config.trace_propagation_targets = CitySocial::SentryConfig.list("SENTRY_TRACE_PROPAGATION_TARGETS")

  # Structured request/job/mailer outcomes give Seer and human responders the
  # chronology around an issue. SQL remains in sampled spans instead of logs to
  # avoid duplicate volume and any chance of query text leaking user content.
  config.enable_logs = CitySocial::SentryConfig.boolean("SENTRY_ENABLE_LOGS", true)
  config.enable_metrics = true
  config.breadcrumbs_logger = [:http_logger]
  config.rails.structured_logging.subscribers = {
    action_controller: Sentry::Rails::LogSubscribers::ActionControllerSubscriber,
    active_job: Sentry::Rails::LogSubscribers::ActiveJobSubscriber,
    action_mailer: Sentry::Rails::LogSubscribers::ActionMailerSubscriber
  }
  config.rails.enable_db_query_source = true
  config.rails.db_query_source_threshold_ms = Integer(ENV.fetch("SENTRY_DB_QUERY_SOURCE_THRESHOLD_MS", 100))
  config.rails.active_job_report_on_retry_error = false

  # Sidekiq owns reporting for the configured ActiveJob adapter, avoiding a
  # duplicate Rails report while preserving queue spans and trace continuity.
  config.sidekiq.propagate_traces = true
  config.sidekiq.report_after_job_retries =
    CitySocial::SentryConfig.boolean("SENTRY_SIDEKIQ_REPORT_AFTER_RETRIES", false)
  config.sidekiq.report_only_dead_jobs =
    CitySocial::SentryConfig.boolean("SENTRY_SIDEKIQ_REPORT_ONLY_DEAD_JOBS", false)
end
