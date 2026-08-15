require "rails_helper"

RSpec.describe Marketplace::Listing, type: :model do
  it "generates a unique slug and sets an expiration" do
    a = create(:listing, title: "Red Couch")
    b = create(:listing, title: "Red Couch")

    expect(a.slug).to eq("red-couch")
    expect(b.slug).to eq("red-couch-2")
    expect(a.expires_at).to be_present
  end

  it "converts price to and from cents and displays it" do
    listing = create(:listing, price: 19.99)
    expect(listing.price_cents).to eq(1999)
    expect(listing.price_display).to eq("$19.99")

    free = create(:listing, price: nil)
    expect(free.price_display).to eq("Free")
  end

  it "searches title and description case-insensitively" do
    match = create(:listing, title: "Vintage Bicycle")
    create(:listing, title: "Office Chair")

    expect(Marketplace::Listing.search("vintage")).to contain_exactly(match)
  end

  it "excludes sold and expired from active_listings and publishes on sale" do
    active = create(:listing)
    create(:listing, status: :sold)
    create(:listing, expires_at: 1.day.ago)

    expect(Marketplace::Listing.active_listings).to contain_exactly(active)

    events = []
    PlatformCore::EventBus.subscribe("marketplace.listing_sold", ->(_n, p) { events << p })
    active.mark_sold!
    expect(active.reload).to be_sold
    expect(events.last).to include(listing_id: active.id)
  end

  it "publishes a content-free feed projection with its attached photo references" do
    allow(PlatformCore::EventBus).to receive(:publish)
    listing = build(:listing, title: "Neighborhood bike")
    listing.photos.attach(
      io: StringIO.new(TestImages.png_1x1),
      filename: "bike.png",
      content_type: "image/png"
    )

    listing.save!

    expect(PlatformCore::EventBus).to have_received(:publish).with(
      "marketplace.listing_created",
      listing_id: listing.id,
      author_id: listing.author_id,
      target_path: "/marketplace/neighborhood-bike",
      media_blob_ids: [listing.photos.blobs.sole.id],
      media_count: 1
    )
  end

  describe "#renew!" do
    it "resurfaces a stale listing and extends the expiration" do
      listing = create(:listing, created_at: 3.days.ago, expires_at: 2.days.from_now)

      expect(listing.renew!).to be(true)
      listing.reload
      expect(listing.created_at).to be_within(1.minute).of(Time.current)
      expect(listing.expires_at).to be_within(1.minute).of(30.days.from_now)
    end

    it "is blocked inside the 48-hour cooldown" do
      listing = create(:listing, created_at: 1.hour.ago)

      expect(listing.renewable?).to be(false)
      expect(listing.renew!).to be(false)
    end

    it "is blocked once the listing is sold" do
      listing = create(:listing, created_at: 3.days.ago, status: :sold)

      expect(listing.renewable?).to be(false)
      expect(listing.renew!).to be(false)
    end
  end
end
