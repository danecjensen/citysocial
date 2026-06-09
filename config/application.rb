require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module CitySocial
  class Application < Rails::Application
    config.load_defaults 7.2

    # Engines under components/ are loaded as gems via the root Gemfile.
    # The host app stays thin: routing, session, the shared shell, and wiring.
    config.autoload_paths << Rails.root.join("app")

    # ActiveJob -> Sidekiq, used by the event bus for cross-module async work.
    config.active_job.queue_adapter = :sidekiq
  end
end
