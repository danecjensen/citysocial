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

    # "Sign in with Google" runs on the OmniAuth Rack middleware. Identity is
    # kernel-owned, so the strategy is registered here rather than in the host.
    # Credentials come from the environment; the request phase is CSRF-protected
    # by omniauth-rails_csrf_protection (loaded via the Gemfile). Missing
    # credentials only fail at request time, so boot is safe without them.
    initializer "platform_core.omniauth" do |app|
      OmniAuth.config.logger = Rails.logger

      app.middleware.use OmniAuth::Builder do
        provider :google_oauth2,
                 ENV.fetch("GOOGLE_CLIENT_ID", nil),
                 ENV.fetch("GOOGLE_CLIENT_SECRET", nil),
                 scope: "email,profile",
                 prompt: "select_account"
      end
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
