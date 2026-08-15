module Feed
  # How feed connects to the rest of the system. This is the reference example
  # every other module copies.
  module Events
    module_function

    def subscribe!
      Feed::IngestActivity::ACTIVITY.each_key do |event_name|
        registered = PlatformCore::EventBus.registry[event_name]
        next if registered.any? { |subscription| subscription.handler == Feed::IngestActivity }

        PlatformCore::EventBus.subscribe(event_name, Feed::IngestActivity)
      end
    end

    # Events feed PUBLISHES:
    #   - "feed.post_created" { post_id:, author_id:, source: }
    #     -> emitted by Feed::PublishPost after a successful create.
    #   - "feed.comment_created", "feed.reaction_changed", "feed.save_changed",
    #     "feed.poll_voted", "feed.post_updated", and "feed.post_deleted".
    #
    # Feed SUBSCRIBES TO every public, resident-facing creation/activity event
    # listed in Feed::IngestActivity::ACTIVITY. Private messaging,
    # notifications, and product-feedback workflow events are intentionally not
    # projected into the public home feed.
  end
end
