module Notifications
  class DeliverDirect
    STATUS_LABELS = {
      "open" => "Open",
      "planned" => "Planned",
      "in_progress" => "In progress",
      "completed" => "Completed",
      "closed" => "Closed"
    }.freeze

    def self.call(event_name, payload)
      case event_name
      when "feedback.submission_status_changed"
        deliver_feedback_status(payload)
      when "communities.comment_created"
        deliver_community_comment(payload)
      end
    end

    def self.deliver_feedback_status(payload)
      submission_id = payload.fetch(:submission_id)
      author_id = payload.fetch(:author_id)
      status_label = STATUS_LABELS.fetch(payload.fetch(:status).to_s)
      notification = Notification.find_or_initialize_by(
        recipient_id: author_id,
        event_name: "feedback.submission_status_changed",
        source_id: submission_id
      )

      notification.assign_attributes(
        actor_id: author_id,
        message: "Your feedback moved to #{status_label}.",
        target_path: "/feedback/submissions/#{submission_id}"
      )
      notification.read_at = nil if notification.new_record? || notification.will_save_change_to_message?
      notification.save!
    end

    def self.deliver_community_comment(payload)
      actor_id = payload.fetch(:author_id)
      recipient_id = payload.fetch(:post_author_id)
      return if actor_id == recipient_id

      actor = PlatformCore::Graph.public_profile(actor_id)
      actor_label = actor ? "@#{actor.handle}" : "A resident"

      Notification.find_or_create_by!(
        recipient_id: recipient_id,
        event_name: "communities.comment_created",
        source_id: payload.fetch(:comment_id)
      ) do |notification|
        notification.actor_id = actor_id
        notification.message = "#{actor_label} commented on your community post."
        notification.target_path = "/communities/#{payload.fetch(:community_slug)}/posts/#{payload.fetch(:post_id)}"
      end
    end

    private_class_method :deliver_feedback_status, :deliver_community_comment
  end
end
