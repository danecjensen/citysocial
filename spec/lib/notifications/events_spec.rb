require "rails_helper"

RSpec.describe Notifications::Events do
  after do
    PlatformCore::EventBus.reset!
    described_class.subscribe!
  end

  it "subscribes the delivery handler asynchronously and only once" do
    PlatformCore::EventBus.reset!

    2.times { described_class.subscribe! }

    %w[feed.post_created communities.post_created].each do |event_name|
      subscriptions = PlatformCore::EventBus.registry.fetch(event_name)
      expect(subscriptions.length).to eq(1)
      expect(subscriptions.first).to have_attributes(handler: Notifications::DeliverActivity, async: true)
    end
  end
end
