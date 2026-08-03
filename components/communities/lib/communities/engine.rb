module Communities
  class Engine < ::Rails::Engine
    isolate_namespace Communities

    # Wire this module's event subscriptions once the app has booted.
    config.after_initialize do
      Communities::Events.subscribe!
    end

    config.generators do |g|
      g.test_framework :rspec
    end

    # Make this engine's migrations run as part of the host app's db:migrate.
    initializer "communities.append_migrations" do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"] << path
        end
      end
    end
  end
end
