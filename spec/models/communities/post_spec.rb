require "rails_helper"

RSpec.describe Communities::Post, type: :model do
  it "auto-upvotes for its author and increments the community post count" do
    community = create(:community)
    post = community.posts.create!(author_id: create(:user).id, title: "Hello there", body: "hi")

    expect(post.score).to eq(1)
    expect(community.reload.posts_count).to eq(1)
  end

  it "infers kind from the presence of a url" do
    expect(create(:community_post, url: nil).kind).to eq("text")
    expect(create(:community_post, url: "https://example.com").kind).to eq("link")
  end

  it "toggles and switches votes, keeping score in sync" do
    post = create(:community_post)
    voter = create(:user)

    post.cast_vote(voter.id, 1)
    expect(post.reload.score).to eq(2) # author auto-upvote + voter

    post.cast_vote(voter.id, 1) # same value toggles off
    expect(post.reload.score).to eq(1)

    post.cast_vote(voter.id, -1)
    expect(post.reload.score).to eq(0)
  end

  it "publishes communities.post_created" do
    events = []
    PlatformCore::EventBus.subscribe("communities.post_created", ->(_name, payload) { events << payload })

    post = create(:community_post)

    expect(events.last).to include(post_id: post.id, community_id: post.community_id, author_id: post.author_id)
  end
end
