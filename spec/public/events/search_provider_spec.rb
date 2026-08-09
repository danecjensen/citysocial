require "rails_helper"

RSpec.describe Events::SearchProvider do
  it "ranks exact title, title prefix, then text matches before chronological ties" do
    text = create(:event, title: "Sunday Showcase", description: "Vintage film restored", starts_at: 1.day.from_now)
    later_prefix = create(:event, title: "Vintage Film Society", starts_at: 4.days.from_now)
    sooner_prefix = create(:event, title: "Vintage Film Night", starts_at: 2.days.from_now)
    exact = create(:event, title: "Vintage Film", starts_at: 6.days.from_now)

    results = described_class.call(query: "VINTAGE FILM", limit: 10)

    expect(results.map(&:title)).to eq([exact.title, sooner_prefix.title, later_prefix.title, text.title])
    expect(results.first.path).to eq("/events/e/#{exact.id}")
    expect(results.first.type).to eq("event")
  end

  it "excludes past events and honors the SQL limit" do
    future = create(:event, title: "Future Jazz", starts_at: 2.days.from_now)
    create(:event, title: "Past Jazz", starts_at: 2.days.ago)
    create(:event, title: "Later Jazz", starts_at: 4.days.from_now)

    results = described_class.call(query: "jazz", limit: 1)

    expect(results.map(&:title)).to eq([future.title])
  end
end
