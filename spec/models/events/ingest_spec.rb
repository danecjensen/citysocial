require "rails_helper"

RSpec.describe Events::Ingest do
  let(:payload) do
    {
      "title" => "La Bohème",
      "venue" => "The Long Center",
      "category" => "performing_arts",
      "starts_at" => "2026-08-08T19:30:00-05:00",
      "url" => "https://austinopera.org/la-boheme",
      "image_url" => "https://austinopera.org/poster.jpg",
      "price" => "$25+",
      "score" => 0.92,
      "why" => "An ambitious production at a favorite venue.",
      "ticket_urgency" => "likely to sell out",
      "age_limit" => "18+",
      "source" => "spoofed-source"
    }
  end

  it "creates a parsed, typed row attributed to the authenticated producer" do
    result = described_class.call(source: "claude-events", external_id: "opera-2026", payload: payload)

    expect(result.status).to eq(:created)
    expect(result.event).to have_attributes(
      source: "claude-events",
      external_id: "opera-2026",
      category: "performing_arts",
      score: 0.92,
      why: "An ambitious production at a favorite venue.",
      ticket_urgency: "likely to sell out",
      age_limit: "18+",
      starts_at: Time.zone.parse("2026-08-08T19:30:00-05:00")
    )
  end

  it "reports an exact retry as a duplicate without another write" do
    first = described_class.call(source: "claude-events", external_id: "opera-2026", payload: payload)
    duplicate = described_class.call(source: "claude-events", external_id: "opera-2026", payload: payload)

    expect(duplicate.status).to eq(:duplicate)
    expect(duplicate.event).to eq(first.event)
    expect(Events::Event.count).to eq(1)
  end

  it "updates mutable data when the same producer identity carries a correction" do
    first = described_class.call(source: "claude-events", external_id: "opera-2026", payload: payload)
    updated = described_class.call(
      source: "claude-events",
      external_id: "opera-2026",
      payload: payload.merge("score" => 0.99, "price" => "$30")
    )

    expect(updated.status).to eq(:updated)
    expect(updated.event.id).to eq(first.event.id)
    expect(updated.event).to have_attributes(score: 0.99, price: "$30")
  end

  it "deduplicates the same real-world event across producer identities" do
    first = described_class.call(source: "claude-events", external_id: "opera-2026", payload: payload)
    duplicate = described_class.call(source: "other-routine", external_id: "other-55", payload: payload)

    expect(duplicate.status).to eq(:duplicate)
    expect(duplicate.event).to eq(first.event)
    expect(duplicate.event).to have_attributes(source: "claude-events", external_id: "opera-2026")
    expect(Events::Event.count).to eq(1)
  end

  it "rejects missing ingestion identity or required event data" do
    result = described_class.call(source: "", external_id: "", payload: { title: "No date" })

    expect(result.status).to eq(:invalid)
    expect(result.errors).to include("source can't be blank", "external ID can't be blank", "starts at can't be blank")
    expect(Events::Event.count).to eq(0)
  end

  it "clamps unknown categories to other" do
    result = described_class.call(
      source: "claude-events", external_id: "opera-2026", payload: payload.merge("category" => "opera-night")
    )

    expect(result.event.category).to eq("other")
  end

  it "publishes a singular ingestion event only when a row is written" do
    allow(PlatformCore::EventBus).to receive(:publish)

    described_class.call(source: "claude-events", external_id: "opera-2026", payload: payload)
    described_class.call(source: "claude-events", external_id: "opera-2026", payload: payload)

    expect(PlatformCore::EventBus).to have_received(:publish).with(
      "events.event_ingested",
      event_id: kind_of(Integer),
      source: "claude-events",
      external_id: "opera-2026",
      status: :created,
      target_path: a_string_matching(%r{\A/events/e/\d+\z})
    ).once
  end

  it "funnels batch feeds through the singular command and reports duplicates" do
    feed = [payload, payload.merge("title" => "Dr. Dog", "url" => nil, "venue" => "Mohawk")]

    first = described_class.call_many(feed, source: "events-routine")
    second = described_class.call_many(feed, source: "events-routine")

    expect(first).to have_attributes(created: 2, updated: 0, duplicates: 0, skipped: 0)
    expect(second).to have_attributes(created: 0, updated: 0, duplicates: 2, skipped: 0)
    expect(Events::Event.count).to eq(2)
  end
end
