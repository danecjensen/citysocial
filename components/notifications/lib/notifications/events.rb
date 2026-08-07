module Notifications
  # All cross-module wiring for Notifications lives here: what it listens
  # for, and (by convention) what it publishes. Keep this file as the honest
  # description of how this module connects to the rest of the system.
  module Events
    module_function

    def subscribe!
      %w[feed.post_created communities.post_created].each do |event_name|
        subscriptions = PlatformCore::EventBus.registry[event_name]
        next if subscriptions.any? { |subscription| subscription.handler == Notifications::DeliverActivity }

        PlatformCore::EventBus.subscribe(event_name, Notifications::DeliverActivity, async: true)
      end
    end

    # Events this module SUBSCRIBES TO:
    #   - "feed.post_created"        { post_id:, author_id: }
    #   - "communities.post_created" { post_id:, community_id:, author_id: }
    #
    # Notifications publishes no events in this milestone.
  end
end
