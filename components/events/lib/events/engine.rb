module Events
  class Engine < ::Rails::Engine
    isolate_namespace Events

    # Wire this module's event subscriptions once the app has booted.
    # Wire this module's event subscriptions once the app has booted. The wiring
    # module is `Events::Wiring` (not the generator's default `Events::Events`)
    # to avoid shadowing the top-level namespace inside `module Events`.
    config.after_initialize do
      Events::Wiring.subscribe!
    end

    config.to_prepare do
      PlatformCore::Search.register(
        key: "events",
        label: "Events",
        module_key: "events",
        types: ["event"],
        callable: Events::SearchProvider,
        more_path: Events::SearchProvider.method(:more_path)
      )
    end

    config.generators do |g|
      g.test_framework :rspec
    end

    # Make this engine's migrations run as part of the host app's db:migrate.
    initializer "events.append_migrations" do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"] << path
        end
      end
    end
  end
end
