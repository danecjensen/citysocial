module Notifications
  class Engine < ::Rails::Engine
    isolate_namespace Notifications

    # Wire this module's event subscriptions once the app has booted.
    config.after_initialize do
      Notifications::Events.subscribe!
    end

    config.generators do |g|
      g.test_framework :rspec
    end

    # Surface the resident's notifications on their own profile (the account hub)
    # rather than in the global nav. The kernel renders whatever is registered
    # here; it never names a Notifications constant.
    config.to_prepare do
      PlatformCore::ProfileLinks.register(
        key: "notifications", label: "Notifications", path: "/notifications/",
        module_key: "notifications", position: 20,
        description: "Updates and new activity across CitySocial.",
        icon: "M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 " \
              "6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
      ) { |user_id| Notifications::Inbox.unread_count_for(user_id) }
    end

    # Make this engine's migrations run as part of the host app's db:migrate.
    initializer "notifications.append_migrations" do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"] << path
        end
      end
    end
  end
end
