require "rails_helper"

RSpec.describe Feedback::Support, type: :model do
  it "allows one support per member and maintains the counter" do
    submission = create(:feedback_submission)
    user = create(:user)

    support = described_class.create!(submission: submission, user_id: user.id)

    expect(submission.reload.supports_count).to eq(1)
    expect(described_class.new(submission: submission, user_id: user.id)).not_to be_valid

    support.destroy!
    expect(submission.reload.supports_count).to eq(0)
  end

  it "publishes an event that can notify the submitter" do
    allow(PlatformCore::EventBus).to receive(:publish)
    submission = create(:feedback_submission)
    supporter = create(:user)

    described_class.create!(submission: submission, user_id: supporter.id)

    expect(PlatformCore::EventBus).to have_received(:publish).with(
      "feedback.submission_supported",
      submission_id: submission.id,
      supporter_id: supporter.id,
      author_id: submission.author_id
    )
  end
end
