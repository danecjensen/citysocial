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
end
