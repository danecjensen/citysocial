module Feed
  class IngestActivity
    ACTIVITY = {
      "marketplace.listing_created" => {
        entity_key: :listing_id, actor_key: :author_id, kind: "marketplace",
        title: "A new marketplace listing was posted", fallback_path: "/marketplace"
      },
      "communities.community_created" => {
        entity_key: :community_id, actor_key: :creator_id, kind: "activity",
        title: "A new local community was started", fallback_path: "/communities"
      },
      "communities.post_created" => {
        entity_key: :post_id, actor_key: :author_id, kind: "activity",
        title: "A resident shared something with a community", fallback_path: "/communities"
      },
      "shared_calendar.event_created" => {
        entity_key: :event_id, actor_key: :author_id, kind: "event",
        title: "A new event was added to the community calendar", fallback_path: "/shared_calendar"
      },
      "pickup_sports.game_created" => {
        entity_key: :game_id, actor_key: :host_id, kind: "game",
        title: "A resident is organizing a pickup game", fallback_path: "/pickup_sports"
      },
      "restaurants.matchup_decided" => {
        entity_key: :vote_id, actor_key: :voter_id, kind: "activity",
        title: "A resident made a pick in the local restaurant rankings", fallback_path: "/restaurants"
      },
      "events.event_ingested" => {
        entity_key: :event_id, actor_key: nil, kind: "event",
        title: "A noteworthy local event was added", fallback_path: "/events"
      }
    }.freeze

    def self.call(event_name, payload)
      activity = ACTIVITY[event_name]
      return unless activity

      entity_id = payload[activity.fetch(:entity_key)]
      return if entity_id.blank?

      source_module = event_name.split(".").first
      Feed::PublishPost.call(
        source: "module:#{source_module}",
        author_id: activity[:actor_key] && payload[activity[:actor_key]],
        external_id: "#{event_name}:#{entity_id}",
        title: activity.fetch(:title),
        kind: activity.fetch(:kind),
        target_path: safe_target_path(payload[:target_path]) || activity.fetch(:fallback_path),
        photos: attached_media(payload[:media_blob_ids]),
        enrich_link: false
      )
    end

    def self.safe_target_path(value)
      path = value.to_s
      return if path.blank? || !path.match?(%r{\A/(?!/)}) || path.match?(/[\\\x00-\x1f\x7f]/)

      path
    end
    private_class_method :safe_target_path

    def self.attached_media(ids)
      ActiveStorage::Blob.where(id: Array(ids).compact_blank.first(Feed::Post::PHOTO_LIMIT)).to_a
    end
    private_class_method :attached_media
  end
end
