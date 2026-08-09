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

  it "notifies a community post author once when another resident comments" do
    post_author = create(:user)
    commenter = create(:user, handle: "helpful_neighbor")
    payload = {
      comment_id: 42,
      post_id: 7,
      community_slug: "eastside",
      author_id: commenter.id,
      post_author_id: post_author.id
    }

    2.times { described_class.call("communities.comment_created", payload) }

    expect(Notifications::Notification.where(recipient_id: post_author.id)).to contain_exactly(
      have_attributes(
        actor_id: commenter.id,
        event_name: "communities.comment_created",
        source_id: 42,
        message: "@helpful_neighbor commented on your community post.",
        target_path: "/communities/eastside/posts/7"
      )
    )
  end

  it "does not notify an author about their own community comment" do
    author = create(:user)

    expect do
      described_class.call(
        "communities.comment_created",
        { comment_id: 42, post_id: 7, community_slug: "eastside", author_id: author.id,
          post_author_id: author.id }
      )
    end.not_to change(Notifications::Notification, :count)
  end
end
