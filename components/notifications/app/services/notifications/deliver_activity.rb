module Notifications
  class DeliverActivity
    ACTIVITY = {
      "feed.post_created" => { source_key: :post_id, target_path: "/feed", action: "shared a feed post" },
      "communities.post_created" => {
        source_key: :post_id,
        target_path: "/communities",
        action: "shared a community post"
      },
      "shared_calendar.event_created" => {
        source_key: :event_id,
        target_path: "/shared_calendar",
        action: "added an event to the community calendar"
      }
    }.freeze

    def self.call(event_name, payload)
      activity = ACTIVITY[event_name]
      return unless activity

      author_id = payload.fetch(:author_id)
      source_id = payload.fetch(activity.fetch(:source_key))
      actor = PlatformCore::Graph.public_profile(author_id)
      actor_label = actor ? "@#{actor.handle}" : "Someone you follow"

      PlatformCore::Graph.follower_ids(author_id).uniq.each do |recipient_id|
        next if recipient_id == author_id

        Notification.find_or_create_by!(
          recipient_id: recipient_id,
          event_name: event_name,
          source_id: source_id
        ) do |notification|
          notification.actor_id = author_id
          notification.message = "#{actor_label} #{activity.fetch(:action)}."
          notification.target_path = activity.fetch(:target_path)
        end
      end
    end
  end
end
