module PickupSports
  class Engine < ::Rails::Engine
    isolate_namespace PickupSports

    config.generators do |g|
      g.test_framework :rspec
    end

    # Make this engine's migrations run as part of the host app's db:migrate.
    initializer "pickup_sports.append_migrations" do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"] << path
        end
      end
    end
  end
end
