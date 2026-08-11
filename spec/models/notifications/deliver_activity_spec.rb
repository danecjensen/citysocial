require "rails_helper"

RSpec.describe Notifications::DeliverActivity do
  it "fans feed activity out to followers only and is idempotent" do
    author = create(:user, handle: "neighbor")
    first_follower = create(:user)
    second_follower = create(:user)
    non_follower = create(:user)
    PlatformCore::Follow.create!(follower_id: first_follower.id, followed_id: author.id)
    PlatformCore::Follow.create!(follower_id: second_follower.id, followed_id: author.id)

    2.times { described_class.call("feed.post_created", post_id: 42, author_id: author.id) }

    expect(Notifications::Notification.pluck(:recipient_id)).to contain_exactly(first_follower.id, second_follower.id)
    expect(Notifications::Notification.where(recipient_id: non_follower.id)).to be_empty
    expect(Notifications::Notification.first).to have_attributes(
      actor_id: author.id,
      message: "@neighbor shared a feed post.",
      target_path: "/feed"
    )
  end

  it "delivers community activity without referencing community models" do
    author = create(:user)
    follower = create(:user)
    PlatformCore::Follow.create!(follower_id: follower.id, followed_id: author.id)

    described_class.call("communities.post_created", post_id: 84, community_id: 7, author_id: author.id)

    expect(Notifications::Notification.last).to have_attributes(
      recipient_id: follower.id,
      event_name: "communities.post_created",
      source_id: 84,
      target_path: "/communities"
    )
  end

  it "fans marketplace listing activity out to followers only and is idempotent" do
    author = create(:user, handle: "seller")
    follower = create(:user)
    non_follower = create(:user)
    PlatformCore::Follow.create!(follower_id: follower.id, followed_id: author.id)

    2.times { described_class.call("marketplace.listing_created", listing_id: 7, author_id: author.id) }

    expect(Notifications::Notification.pluck(:recipient_id)).to contain_exactly(follower.id)
    expect(Notifications::Notification.where(recipient_id: non_follower.id)).to be_empty
    expect(Notifications::Notification.last).to have_attributes(
      actor_id: author.id,
      event_name: "marketplace.listing_created",
      source_id: 7,
      message: "@seller posted a marketplace listing.",
      target_path: "/marketplace"
    )
  end
end
