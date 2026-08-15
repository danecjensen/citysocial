require "rails_helper"

RSpec.describe Feed::IngestActivity do
  before do
    PlatformCore::EventBus.reset!
    Feed::Events.subscribe!
  end

  after { PlatformCore::EventBus.reset! }

  it "subscribes exactly once to every public module activity" do
    2.times { Feed::Events.subscribe! }

    expect(described_class::ACTIVITY.keys).to contain_exactly(
      "marketplace.listing_created",
      "communities.community_created",
      "communities.post_created",
      "shared_calendar.event_created",
      "pickup_sports.game_created",
      "restaurants.matchup_decided",
      "events.event_ingested"
    )
    described_class::ACTIVITY.each_key do |event_name|
      subscriptions = PlatformCore::EventBus.registry.fetch(event_name)
      expect(subscriptions.count { |subscription| subscription.handler == described_class }).to eq(1)
    end
  end

  it "projects activity without reading a sibling module model and is retry-safe" do
    author = create(:user)
    payload = {
      listing_id: 91,
      author_id: author.id,
      target_path: "/marketplace/bike",
      media_blob_ids: []
    }

    2.times { PlatformCore::EventBus.publish("marketplace.listing_created", **payload) }

    expect(Feed::Post.where(source: "module:marketplace").sole).to have_attributes(
      author_id: author.id,
      kind: "marketplace",
      title: "A new marketplace listing was posted",
      target_path: "/marketplace/bike"
    )
  end

  it "attaches shared media by opaque blob id" do
    author = create(:user)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(TestImages.png_1x1),
      filename: "event.png",
      content_type: "image/png"
    )

    PlatformCore::EventBus.publish(
      "shared_calendar.event_created",
      event_id: 17,
      author_id: author.id,
      target_path: "/shared_calendar/17",
      media_blob_ids: [blob.id]
    )

    expect(Feed::Post.where(source: "module:shared_calendar").sole.photos).to be_attached
  end

  it "includes module activity alongside posts from followed residents" do
    resident = create(:user)
    stranger = create(:user)
    Feed::PublishPost.call(source: "web", author_id: stranger.id, body: "Private to their network")
    PlatformCore::EventBus.publish("events.event_ingested", event_id: 4, target_path: "/events/e/4")

    timeline = Feed::Timeline.for_user(resident.id)

    expect(timeline.map(&:source)).to include("module:events")
    expect(timeline.map(&:body)).not_to include("Private to their network")
  end
end
