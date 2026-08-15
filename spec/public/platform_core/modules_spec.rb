require "rails_helper"

RSpec.describe PlatformCore::Modules do
  describe ".primary_nav_modules" do
    it "returns exactly Feed, Events, Restaurants in that order" do
      keys = described_class.primary_nav_modules.map(&:key)

      expect(keys).to eq(%w[feed events restaurants])
    end

    it "drops a primary module when it is disabled" do
      described_class.disable!("events")

      expect(described_class.primary_nav_modules.map(&:key)).to eq(%w[feed restaurants])
    ensure
      described_class.enable!("events")
    end
  end

  describe ".secondary_nav_modules" do
    it "returns the remaining nav modules and none of the primary ones" do
      keys = described_class.secondary_nav_modules.map(&:key)

      expect(keys).to include("communities", "marketplace", "shared_calendar", "pickup_sports", "feedback")
      expect(keys).not_to include("feed", "events", "restaurants")
    end

    it "excludes non-nav modules such as messaging and notifications" do
      keys = described_class.secondary_nav_modules.map(&:key)

      expect(keys).not_to include("messaging", "notifications")
    end
  end
end
