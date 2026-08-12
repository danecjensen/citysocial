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

    # Surface the resident's inbox on their own profile (the account hub) rather
    # than in the global nav. The kernel renders whatever is registered here; it
    # never names a Messaging constant.
    config.to_prepare do
      PlatformCore::ProfileLinks.register(
        key: "messages", label: "Messages", path: "/messaging/",
        module_key: "messaging", position: 10,
        description: "Your private conversations with neighbors.",
        icon: "M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
      ) { |user_id| Messaging::Inbox.unread_count(user_id) }
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
