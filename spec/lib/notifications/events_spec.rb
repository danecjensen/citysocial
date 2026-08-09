require "rails_helper"

RSpec.describe Notifications::Events do
  after do
    PlatformCore::EventBus.reset!
    described_class.subscribe!
  end

  it "subscribes the delivery handler asynchronously and only once" do
    PlatformCore::EventBus.reset!

    2.times { described_class.subscribe! }

    expected = {
      "feed.post_created" => Notifications::DeliverActivity,
      "communities.post_created" => Notifications::DeliverActivity,
      "feedback.submission_status_changed" => Notifications::DeliverDirect
    }

    expected.each do |event_name, handler|
      subscriptions = PlatformCore::EventBus.registry.fetch(event_name)
      expect(subscriptions.length).to eq(1)
      expect(subscriptions.first).to have_attributes(handler: handler, async: true)
    end

    expect(PlatformCore::EventBus.registry["feedback.submission_created"]).to be_empty
  end
end
