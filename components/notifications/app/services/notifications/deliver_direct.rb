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
      return unless event_name == "feedback.submission_status_changed"

      submission_id = payload.fetch(:submission_id)
      author_id = payload.fetch(:author_id)
      status_label = STATUS_LABELS.fetch(payload.fetch(:status).to_s)
      notification = Notification.find_or_initialize_by(
        recipient_id: author_id,
        event_name: event_name,
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
  end
end
