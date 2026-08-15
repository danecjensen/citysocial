# frozen_string_literal: true

# PostHog is the product analytics system. Sentry remains the source of truth
# for errors and performance, so exception, job, and log duplication stays off.
posthog_requested = ActiveModel::Type::Boolean.new.cast(
  ENV.fetch("POSTHOG_ENABLED", Rails.env.production?.to_s)
)
posthog_token = ENV.fetch("POSTHOG_PROJECT_TOKEN", "").strip

Rails.application.config.x.posthog.enabled = posthog_requested && posthog_token.present?
Rails.application.config.x.posthog.project_token = posthog_token
Rails.application.config.x.posthog.host = ENV.fetch("POSTHOG_HOST", "https://us.i.posthog.com").strip

PostHog::Rails.configure do |config|
  config.auto_capture_exceptions = false
  config.report_rescued_exceptions = false
  config.auto_instrument_active_job = false
  config.logs_enabled = false

  # These browser-provided values are analytics correlation only. Application
  # authorization always uses the Rails session and explicit current_user id.
  config.use_tracing_headers = true
  config.capture_user_context = false
end

if Rails.configuration.x.posthog.enabled
  PostHog::Logging.logger = Rails.logger

  PostHog.init do |config|
    config.api_key = Rails.configuration.x.posthog.project_token
    config.host = Rails.configuration.x.posthog.host
    config.max_queue_size = 10_000
    config.feature_flag_request_timeout_seconds = 2
    config.on_error = proc do |status, message|
      Rails.logger.warn("event=posthog_delivery_failed status=#{status.inspect} message=#{message.inspect}")
    end
    config.before_send = proc do |event|
      properties = event[:properties] || event["properties"] || {}
      properties.delete("$ip")
      properties.delete(:$ip)
      properties["app_environment"] = Rails.env

      release = ENV["HEROKU_SLUG_COMMIT"].presence || ENV["GIT_SHA"].presence
      properties["app_release"] = release if release
      event
    end
  end
end
