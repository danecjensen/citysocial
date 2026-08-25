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

  describe "EATER_38" do
    it "names all 38 restaurants on the Eater Austin map" do
      expect(described_class::EATER_38.size).to eq(38)
    end

    it "references only names that exist in the SEED catalog" do
      seed_names = described_class::SEED.pluck(:name)
      expect(described_class::EATER_38 - seed_names).to be_empty
    end
  end

  describe ".missing_eater38" do
    it "reports every Eater 38 restaurant when the table is empty" do
      expect(described_class.missing_eater38).to match_array(described_class::EATER_38)
    end

    it "reports nothing once the Eater 38 have been synced" do
      described_class.sync_eater38!
      expect(described_class.missing_eater38).to be_empty
    end

    it "ignores case when matching existing rows" do
      create(:restaurant, name: "franklin barbecue")
      expect(described_class.missing_eater38).not_to include("Franklin Barbecue")
    end
  end

  describe ".sync_eater38!" do
    it "creates the Eater 38 restaurants and returns the ones it created" do
      created = described_class.sync_eater38!
      expect(created.map(&:name)).to match_array(described_class::EATER_38)
      expect(Restaurants::Restaurant.where(name: described_class::EATER_38).count).to eq(38)
    end

    it "adds only the Eater 38 subset, not the whole SEED catalog" do
      described_class.sync_eater38!
      expect(Restaurants::Restaurant.count).to eq(38)
    end

    it "is idempotent" do
      described_class.sync_eater38!
      expect { described_class.sync_eater38! }.not_to change(Restaurants::Restaurant, :count)
      expect(described_class.sync_eater38!).to be_empty
    end

    it "leaves restaurants added another way untouched" do
      existing = create(:restaurant, name: "Franklin Barbecue", cuisine: "Smokehouse", area: "Somewhere")
      described_class.sync_eater38!
      expect(existing.reload.cuisine).to eq("Smokehouse")
    end

    it "still creates every row when attaching a photo fails (job backend down)" do
      allow_any_instance_of(ActiveStorage::Attached::Many)
        .to receive(:attach).and_raise(RuntimeError, "Redis unreachable")
      allow(Rails.logger).to receive(:error)

      expect { described_class.sync_eater38! }.to change(Restaurants::Restaurant, :count).by(38)
      expect(described_class.missing_eater38).to be_empty
      expect(Rails.logger).to have_received(:error).with(/restaurant_seed_photo_failed/).at_least(:once)
    end
  end
end
