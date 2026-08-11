module PlatformCore
  class Engine < ::Rails::Engine
    isolate_namespace PlatformCore

    # Modules register their event subscriptions in their own engines.
    # The bus itself lives in the shared kernel so every module can reach it.
    config.generators do |g|
      g.test_framework :rspec
    end

    # The kernel's own sections on the single-page admin dashboard. Modules add
    # theirs the same way from their own engines.
    config.to_prepare do
      PlatformCore::AdminSections.register(
        key: "users", label: "Users", position: 10,
        description: "Accounts, admin access, and removals."
      ) { PlatformCore::Admin::UsersSectionComponent.new }

      PlatformCore::AdminSections.register(
        key: "modules", label: "Modules", position: 20,
        description: "Turn app-modules on and off across the whole site."
      ) { PlatformCore::Admin::ModulesSectionComponent.new }
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
