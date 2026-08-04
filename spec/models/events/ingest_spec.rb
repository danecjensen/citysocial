require "rails_helper"

RSpec.describe Events::Ingest do
  let(:feed) do
    [
      {
        "title" => "La Bohème",
        "venue" => "The Long Center",
        "category" => "performing_arts",
        "starts_at" => "2026-08-08T19:30:00-05:00",
        "url" => "https://austinopera.org/la-boheme",
        "image_url" => "https://austinopera.org/poster.jpg",
        "price" => "$25+",
        "score" => 0.92,
        "source" => "austinopera.org"
      },
      {
        "title" => "Dr. Dog",
        "venue" => "Mohawk",
        "category" => "music",
        "starts_at" => "2026-08-09T20:00:00-05:00",
        "score" => 0.80
      }
    ]
  end

  it "creates one row per event with parsed, typed attributes" do
    result = described_class.call(feed)

    expect(result.created).to eq(2)
    expect(Events::Event.count).to eq(2)

    opera = Events::Event.find_by(title: "La Bohème")
    expect(opera.category).to eq("performing_arts")
    expect(opera.score).to eq(0.92)
    expect(opera.starts_at).to eq(Time.zone.parse("2026-08-08T19:30:00-05:00"))
  end

  it "is idempotent — re-ingesting the same feed updates, never duplicates" do
    described_class.call(feed)
    result = described_class.call(feed)

    expect(Events::Event.count).to eq(2)
    expect(result.created).to eq(0)
    expect(result.updated).to eq(2)
  end

  it "updates mutable fields on re-ingest while keeping the same row" do
    described_class.call(feed)
    id = Events::Event.find_by(title: "Dr. Dog").id

    described_class.call([feed[1].merge("score" => 0.99, "price" => "$30")])

    row = Events::Event.find(id)
    expect(row.score).to eq(0.99)
    expect(row.price).to eq("$30")
  end

  it "skips records missing a title or start time, counting them" do
    result = described_class.call([{ "title" => "No date" }, { "starts_at" => "2026-08-08T19:30:00-05:00" }])

    expect(result.created).to eq(0)
    expect(result.skipped).to eq(2)
    expect(Events::Event.count).to eq(0)
  end

  it "clamps unknown categories to 'other'" do
    described_class.call([feed[0].merge("category" => "opera-night")])
    expect(Events::Event.first.category).to eq("other")
  end

  it "publishes events.events_ingested when at least one row is written" do
    payloads = []
    PlatformCore::EventBus.subscribe("events.events_ingested", ->(_n, p) { payloads << p })

    described_class.call(feed)

    expect(payloads.last).to include(created: 2)
  end
end
