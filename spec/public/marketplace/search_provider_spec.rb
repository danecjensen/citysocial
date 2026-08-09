require "rails_helper"

RSpec.describe Marketplace::SearchProvider do
  it "ranks exact title, title prefix, then body matches with deterministic recency ties" do
    body = create(
      :listing,
      title: "Handmade Bookshelf",
      description: "A vintage lamp is pictured",
      created_at: 1.hour.ago
    )
    older_prefix = create(:listing, title: "Vintage Lamp Shade", created_at: 2.days.ago)
    newer_prefix = create(:listing, title: "Vintage Lamp Stand", created_at: 1.day.ago)
    exact = create(:listing, title: "Vintage Lamp", created_at: 3.days.ago)

    results = described_class.call(query: "  VINTAGE LAMP  ", limit: 10)

    expect(results.map(&:title)).to eq([exact.title, newer_prefix.title, older_prefix.title, body.title])
    expect(results.first.path).to eq("/marketplace/#{exact.slug}")
    expect(results.first.type).to eq("listing")
  end

  it "returns only active, unexpired listings and honors the SQL limit" do
    active = create(:listing, title: "Active Bicycle", created_at: 1.hour.ago)
    create(:listing, title: "Sold Bicycle", status: :sold)
    create(:listing, title: "Expired Bicycle", expires_at: 1.day.ago)
    create(:listing, title: "Another Bicycle", created_at: 2.days.ago)

    results = described_class.call(query: "bicycle", limit: 1)

    expect(results.map(&:title)).to eq([active.title])
  end
end
