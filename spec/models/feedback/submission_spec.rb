require "rails_helper"

RSpec.describe Feedback::Submission, type: :model do
  it "validates its type, status, content, and safe page context" do
    submission = described_class.new(
      author_id: create(:user).id,
      kind: "unknown",
      status: "maybe",
      title: "No",
      description: "Too short",
      page_url: "javascript:alert(1)"
    )

    expect(submission).not_to be_valid
    expect(submission.errors).to include(:kind, :status, :title, :description, :page_url)
  end

  it "accepts internal paths and http URLs as page context" do
    internal = build(:feedback_submission, page_url: "/marketplace/42")
    external = build(:feedback_submission, page_url: "https://example.com/context")

    expect(internal).to be_valid
    expect(external).to be_valid
  end

  it "reads its author through the platform graph" do
    user = create(:user)
    submission = create(:feedback_submission, author_id: user.id)

    expect(submission.author).to eq(user)
  end

  it "publishes creation and status-change events" do
    allow(PlatformCore::EventBus).to receive(:publish)
    submission = create(:feedback_submission)

    expect(PlatformCore::EventBus).to have_received(:publish).with(
      "feedback.submission_created",
      submission_id: submission.id,
      author_id: submission.author_id,
      kind: "idea",
      area: "feed"
    )

    submission.update!(status: "planned")
    expect(PlatformCore::EventBus).to have_received(:publish).with(
      "feedback.submission_status_changed",
      submission_id: submission.id,
      author_id: submission.author_id,
      status: "planned"
    )
  end
end
