require "rails_helper"

RSpec.describe Restaurants::Vote, type: :model do
  describe ".recent" do
    it "returns the most recent decisions first, breaking ties by id" do
      winner = create(:restaurant)
      loser = create(:restaurant)

      oldest = Restaurants::Vote.create!(voter_id: 1, winner_id: winner.id, loser_id: loser.id, created_at: 2.days.ago)
      middle = Restaurants::Vote.create!(voter_id: 1, winner_id: loser.id, loser_id: winner.id, created_at: 1.day.ago)
      newest = Restaurants::Vote.create!(voter_id: 1, winner_id: winner.id, loser_id: loser.id)

      expect(Restaurants::Vote.recent.to_a).to eq([newest, middle, oldest])
    end
  end
end
