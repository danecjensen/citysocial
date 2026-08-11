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

    # This module's slice of the single-page admin dashboard. The kernel renders
    # whatever is registered here; it never names a Restaurants constant.
    config.to_prepare do
      PlatformCore::AdminSections.register(
        key: "restaurants", label: "Restaurants", module_key: "restaurants", position: 30,
        description: "Add spots, edit their details, and manage their photos."
      ) { |params| Restaurants::Admin::SectionComponent.new(params: params) }
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
