module Restaurants
  class Engine < ::Rails::Engine
    isolate_namespace Restaurants

    # Wire this module's event subscriptions once the app has booted.
    config.after_initialize do
      Restaurants::Events.subscribe!
    end

    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "restaurants.append_migrations" do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"] << path
        end
      end
    end
  end
end
