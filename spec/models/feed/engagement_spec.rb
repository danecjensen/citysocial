require "rails_helper"

RSpec.describe "Feed engagement" do
  let(:author) { create(:user) }
  let(:resident) { create(:user) }
  let(:post_record) { Feed::PublishPost.call(source: "web", author_id: author.id, body: "Neighbor update").post }

  it "creates comments through the canonical response path and publishes a content-free event" do
    allow(PlatformCore::EventBus).to receive(:publish)

    result = Feed::CreateComment.call(post: post_record, author_id: resident.id, body: "  I can help.  ")

    expect(result).to be_success
    expect(result.comment.body).to eq("I can help.")
    expect(post_record.reload.comments_count).to eq(1)
    expect(PlatformCore::EventBus).to have_received(:publish).with(
      "feed.comment_created",
      comment_id: result.comment.id,
      post_id: post_record.id,
      author_id: resident.id,
      post_author_id: author.id
    )
  end

  it "toggles one lightweight reaction per resident" do
    expect(Feed::ReactToPost.call(post: post_record, user_id: resident.id, kind: "helpful")).to eq(:added)
    expect(Feed::ReactToPost.call(post: post_record, user_id: resident.id, kind: "celebrate")).to eq(:changed)
    expect(post_record.reactions.reload.sole.kind).to eq("celebrate")
    expect(post_record.reload.reactions_count).to eq(1)

    expect(Feed::ReactToPost.call(post: post_record, user_id: resident.id, kind: "celebrate")).to eq(:removed)
    expect(post_record.reload.reactions_count).to eq(0)
  end

  it "toggles saved posts privately to the resident" do
    expect(Feed::ToggleSave.call(post: post_record, user_id: resident.id)).to eq(:saved)
    expect(Feed::Timeline.for_user(resident.id, saved: true)).to contain_exactly(post_record)

    expect(Feed::ToggleSave.call(post: post_record, user_id: resident.id)).to eq(:removed)
    expect(Feed::Timeline.for_user(resident.id, saved: true)).to be_empty
  end

  it "lets a resident switch a poll vote while retaining one vote" do
    poll = Feed::PublishPost.call(
      source: "web",
      author_id: author.id,
      kind: "poll",
      title: "Best park for a picnic?",
      poll_options: %w[Mueller Zilker]
    ).post

    first, second = poll.poll_options
    expect(Feed::CastPollVote.call(post: poll, option: first, user_id: resident.id)).to eq(:voted)
    expect(Feed::CastPollVote.call(post: poll, option: second, user_id: resident.id)).to eq(:changed)
    expect(poll.poll_votes.reload.sole.poll_option).to eq(second)
    expect(first.reload.votes_count).to eq(0)
    expect(second.reload.votes_count).to eq(1)
  end
end
