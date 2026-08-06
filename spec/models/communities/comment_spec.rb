require "rails_helper"

RSpec.describe Communities::Comment, type: :model do
  it "sorts top comments by score, then newest first" do
    post = create(:community_post)
    author = create(:user)
    older_high_score = described_class.create!(post: post, author_id: author.id, body: "Older high score",
                                               created_at: 2.hours.ago)
    newer_high_score = described_class.create!(post: post, author_id: author.id, body: "Newer high score",
                                               created_at: 1.hour.ago)
    low_score = described_class.create!(post: post, author_id: author.id, body: "Low score", created_at: Time.current)
    older_high_score.update_column(:score, 5)
    newer_high_score.update_column(:score, 5)
    low_score.update_column(:score, 1)

    expect(post.comments.top).to eq([newer_high_score, older_high_score, low_score])
  end
end
