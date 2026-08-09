module Marketplace
  class Engine < ::Rails::Engine
    isolate_namespace Marketplace

    # Wire this module's event subscriptions once the app has booted.
    config.after_initialize do
      Marketplace::Events.subscribe!
    end

    config.to_prepare do
      PlatformCore::Search.register(
        key: "marketplace",
        label: "Marketplace",
        module_key: "marketplace",
        types: ["listing"],
        callable: Marketplace::SearchProvider,
        more_path: Marketplace::SearchProvider.method(:more_path)
      )
    end

    config.generators do |g|
      g.test_framework :rspec
    end

    # Make this engine's migrations run as part of the host app's db:migrate.
    initializer "marketplace.append_migrations" do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"] << path
        end
      end
    end
  end
end
