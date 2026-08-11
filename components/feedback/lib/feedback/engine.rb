module Feedback
  class Engine < ::Rails::Engine
    isolate_namespace Feedback

    # Wire this module's event subscriptions once the app has booted.
    config.after_initialize do
      Feedback::Events.subscribe!
    end

    config.generators do |g|
      g.test_framework :rspec
    end

    # This module's slice of the single-page admin dashboard. The kernel renders
    # whatever is registered here; it never names a Feedback constant.
    config.to_prepare do
      PlatformCore::AdminSections.register(
        key: "feedback", label: "Feedback", module_key: "feedback", position: 40,
        description: "Triage the public roadmap and keep submitters informed."
      ) { |params| Feedback::Admin::SectionComponent.new(params: params) }
    end

    # Make this engine's migrations run as part of the host app's db:migrate.
    initializer "feedback.append_migrations" do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"] << path
        end
      end
    end
  end
end
