module PlatformCore
  class Engine < ::Rails::Engine
    isolate_namespace PlatformCore

    # Modules register their event subscriptions in their own engines.
    # The bus itself lives in the shared kernel so every module can reach it.
    config.generators do |g|
      g.test_framework :rspec
    end

    # These engines are path gems, not installed with copied migrations, so
    # surface their migrations to the host app's migration paths.
    initializer "platform_core.append_migrations" do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"] << path
        end
      end
    end
  end
end
