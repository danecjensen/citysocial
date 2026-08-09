require "rails_helper"

RSpec.describe Notifications::DeliverDirect do
  it "resurfaces one author notification for each new feedback status" do
    author = create(:user)
    payload = { submission_id: 42, author_id: author.id }

    described_class.call("feedback.submission_status_changed", payload.merge(status: "planned"))
    notification = Notifications::Notification.find_by!(recipient_id: author.id)
    expect(notification).to have_attributes(
      actor_id: author.id,
      event_name: "feedback.submission_status_changed",
      source_id: 42,
      message: "Your feedback moved to Planned.",
      target_path: "/feedback/submissions/42"
    )

    notification.mark_read!
    expect do
      described_class.call("feedback.submission_status_changed", payload.merge(status: "completed"))
    end.not_to change(Notifications::Notification, :count)

    expect(notification.reload).to have_attributes(
      message: "Your feedback moved to Completed.",
      read_at: nil
    )
  end

  it "does not re-alert the author when the same delivery is retried" do
    author = create(:user)
    payload = { submission_id: 42, author_id: author.id, status: "planned" }
    described_class.call("feedback.submission_status_changed", payload)
    notification = Notifications::Notification.find_by!(recipient_id: author.id)
    notification.mark_read!

    described_class.call("feedback.submission_status_changed", payload)

    expect(notification.reload).not_to be_unread
  end
end
