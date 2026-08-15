require "rails_helper"

RSpec.describe PlatformCore::Analytics do
  around do |example|
    config = Rails.configuration.x.posthog
    original = {
      enabled: config.enabled,
      project_token: config.project_token,
      host: config.host
    }

    config.enabled = true
    config.project_token = "phc_test"
    config.host = "https://us.i.posthog.com"
    example.run
  ensure
    config.enabled = original[:enabled]
    config.project_token = original[:project_token]
    config.host = original[:host]
  end

  before do
    allow(PostHog).to receive(:initialized?).and_return(true)
    allow(PostHog).to receive(:capture)
    allow(PostHog).to receive(:identify)
  end

  it "uses one stable, non-PII distinct id in the browser and server" do
    user = build(:user, id: 42)

    expect(described_class.distinct_id(user)).to eq("user_42")
    expect(user.posthog_distinct_id).to eq("user_42")
  end

  it "exposes only the public project configuration to the browser" do
    expect(described_class.browser_config).to eq(
      project_token: "phc_test",
      host: "https://us.i.posthog.com"
    )
  end

  it "identifies accounts without sending email, handle, or profile fields" do
    user = build(:user, id: 42, admin: false, created_at: Time.zone.parse("2026-08-14 12:00:00"))

    described_class.identify(user)

    expect(PostHog).to have_received(:identify).with(
      distinct_id: "user_42",
      properties: {
        account_type: "resident",
        account_created_at: "2026-08-14T12:00:00Z"
      }
    )
  end

  it "bridges domain events with an inferred actor and strips content fields" do
    described_class.capture_domain_event(
      "feed.post_created",
      author_id: 42,
      post_id: 7,
      body: "resident-authored content",
      source_url: "https://example.com/private?token=secret"
    )

    expect(PostHog).to have_received(:capture) do |event|
      expect(event).to include(event: "feed post created", distinct_id: "user_42")
      expect(event[:properties]).to include(
        "post_id" => 7,
        "domain_event" => "feed.post_created",
        "domain_module" => "feed",
        "event_schema_version" => 1,
        "analytics_source" => "server"
      )
      expect(event[:properties]).not_to include("body", "source_url", "author_id")
    end
  end

  it "captures actorless events without creating person profiles" do
    described_class.capture("events imported", properties: { count: 12 })

    expect(PostHog).to have_received(:capture) do |event|
      expect(event).not_to have_key(:distinct_id)
      expect(event[:properties]).to include(
        "count" => 12,
        "$process_person_profile" => false
      )
    end
  end

  it "prefers the resident who performed an action over its recipient or owner" do
    described_class.capture_domain_event(
      "feedback.submission_supported",
      supporter_id: 9,
      author_id: 42,
      submission_id: 7,
      event_schema_version: 2
    )

    expect(PostHog).to have_received(:capture).with(
      hash_including(
        event: "feedback submission supported",
        distinct_id: "user_9",
        properties: hash_including(
          "author_id" => 42,
          "event_schema_version" => 2
        )
      )
    )
  end

  it "does nothing when PostHog is disabled" do
    Rails.configuration.x.posthog.enabled = false

    expect(described_class.capture("feed post created", user_id: 42)).to be(false)
    expect(PostHog).not_to have_received(:capture)
  end

  it "receives every event published through the shared event bus" do
    allow(described_class).to receive(:capture_domain_event)

    PlatformCore::EventBus.publish("feed.post_created", author_id: 42, post_id: 7)

    expect(described_class).to have_received(:capture_domain_event).with(
      "feed.post_created",
      { author_id: 42, post_id: 7 }
    )
  end
end
