module Notifications
  # All cross-module wiring for Notifications lives here: what it listens
  # for, and (by convention) what it publishes. Keep this file as the honest
  # description of how this module connects to the rest of the system.
  module Events
    module_function

    def subscribe!
      subscriptions.each do |event_name, handler|
        registered = PlatformCore::EventBus.registry[event_name]
        next if registered.any? { |subscription| subscription.handler == handler }

        PlatformCore::EventBus.subscribe(event_name, handler, async: true)
      end
    end

    def subscriptions
      {
        "feed.post_created" => Notifications::DeliverActivity,
        "communities.post_created" => Notifications::DeliverActivity,
        "marketplace.listing_created" => Notifications::DeliverActivity,
        "feedback.submission_status_changed" => Notifications::DeliverDirect
      }
    end

    # Events this module SUBSCRIBES TO:
    #   - "feed.post_created"        { post_id:, author_id: }
    #   - "communities.post_created" { post_id:, community_id:, author_id: }
    #   - "marketplace.listing_created" { listing_id:, author_id: }
    #   - "feedback.submission_status_changed"
    #       { submission_id:, author_id:, status: }
    #
    # Notifications publishes no events in this milestone.
  end
end
