module Restaurants
  # One recorded matchup decision: a voter picked winner over loser. Persisted
  # for history and as the natural place to announce the decision to the system.
  class Vote < ApplicationRecord
    validates :voter_id, :winner_id, :loser_id, presence: true

    def winner
      Restaurants::Restaurant.find_by(id: winner_id)
    end

    def loser
      Restaurants::Restaurant.find_by(id: loser_id)
    end

    # Cross-module communication: announce, don't call. Nothing subscribes yet
    # (see lib/restaurants/events.rb), but the contract is published here.
    after_create_commit do
      PlatformCore::EventBus.publish(
        "restaurants.matchup_decided",
        vote_id: id, voter_id: voter_id, winner_id: winner_id, loser_id: loser_id
      )
    end
  end
end
