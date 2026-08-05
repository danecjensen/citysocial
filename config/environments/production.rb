Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Terminate TLS at the platform edge (Heroku) and force HTTPS.
  config.force_ssl = true
  config.assume_ssl = true

  # Active Storage on S3 (Heroku Bucketeer addon). Heroku's dyno filesystem is
  # ephemeral and per-dyno, so Disk storage cannot persist or share uploads --
  # blobs must live in an external object store. The `amazon` service in
  # config/storage.yml reads the BUCKETEER_* credentials the addon sets.
  config.active_storage.service = :amazon

  # Heroku captures the dyno's stdout/stderr; log there instead of to a file.
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end
end
