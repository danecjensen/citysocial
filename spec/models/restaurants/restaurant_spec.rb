require "rails_helper"

RSpec.describe Restaurants::Restaurant, type: :model do
  describe "photos" do
    it "can have photos attached via Active Storage" do
      restaurant = create(:restaurant, :with_photo)

      expect(restaurant.photos).to be_attached
      expect(restaurant.photos.count).to eq(1)
    end

    it "exposes the first attached photo as the hero photo" do
      restaurant = create(:restaurant, :with_photo)

      expect(restaurant.hero_photo).to eq(restaurant.photos.first)
    end

    it "returns nil for hero_photo when nothing is attached" do
      expect(create(:restaurant).hero_photo).to be_nil
    end
  end

  describe ".by_cuisine" do
    it "narrows to matching restaurants when a cuisine is given" do
      bbq = create(:restaurant, cuisine: "BBQ")
      create(:restaurant, cuisine: "Tacos")

      expect(described_class.by_cuisine("BBQ")).to contain_exactly(bbq)
    end

    it "is a no-op for a blank cuisine" do
      create(:restaurant, cuisine: "BBQ")
      create(:restaurant, cuisine: "Tacos")

      expect(described_class.by_cuisine(nil).count).to eq(2)
      expect(described_class.by_cuisine("").count).to eq(2)
    end
  end

  describe ".cuisines" do
    it "returns the distinct present cuisines, sorted" do
      create(:restaurant, cuisine: "Tacos")
      create(:restaurant, cuisine: "BBQ")
      create(:restaurant, cuisine: "Tacos")

      expect(described_class.cuisines).to eq(%w[BBQ Tacos])
    end
  end

  describe ".random_pair" do
    it "eager-loads photos and returns two restaurants" do
      create(:restaurant, :with_photo)
      create(:restaurant, :with_photo)

      pair = described_class.random_pair

      expect(pair.size).to eq(2)
      expect(pair.first.hero_photo).to be_present
    end

    it "returns nil when there aren't two restaurants" do
      create(:restaurant)
      expect(described_class.random_pair).to be_nil
    end
  end
end
