Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Terminate TLS at the platform edge (Heroku) and force HTTPS.
  config.force_ssl = true
  config.assume_ssl = true

  # Heroku captures the dyno's stdout/stderr; log there instead of to a file.
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end
end
