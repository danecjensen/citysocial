Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?
  config.consider_all_requests_local = true
  config.action_dispatch.show_exceptions = :rescuable
  config.active_support.deprecation = :stderr
  config.action_controller.allow_forgery_protection = false
  config.active_storage.service = :test
  # Tests must not depend on a running Redis/Sidekiq. The :test adapter enqueues
  # jobs (e.g. Active Storage's AnalyzeJob) into an in-memory array instead of
  # pushing them to Redis, keeping the suite deterministic and self-contained.
  config.active_job.queue_adapter = :test
end
