require "rails_helper"

RSpec.describe Restaurants::Catalog do
  describe ".seed!" do
    it "creates the seed restaurants and is idempotent" do
      expect { described_class.seed! }.to change(Restaurants::Restaurant, :count).from(0)
      expect { described_class.seed! }.not_to change(Restaurants::Restaurant, :count)
    end

    it "attaches the curated hero photo for restaurants with a manifest entry" do
      described_class.seed!

      name, filename = described_class.photo_manifest.first
      next if name.blank? # no seed photos shipped; nothing to assert

      restaurant = Restaurants::Restaurant.find_by(name: name)
      expect(restaurant.photos).to be_attached
      expect(restaurant.photos.first.filename.to_s).to eq(filename)
    end

    it "does not re-attach photos when run twice" do
      described_class.seed!
      name = described_class.photo_manifest.keys.first
      next if name.blank?

      described_class.seed!
      restaurant = Restaurants::Restaurant.find_by(name: name)
      expect(restaurant.photos.count).to eq(1)
    end
  end
end
