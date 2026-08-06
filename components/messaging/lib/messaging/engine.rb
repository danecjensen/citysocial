module Messaging
  class Engine < ::Rails::Engine
    isolate_namespace Messaging

    # Wire this module's event subscriptions once the app has booted.
    config.after_initialize do
      Messaging::Events.subscribe!
    end

    config.generators do |g|
      g.test_framework :rspec
    end

    # Make this engine's migrations run as part of the host app's db:migrate.
    initializer "messaging.append_migrations" do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"] << path
        end
      end
    end
  end
end
