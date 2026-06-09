module Restaurants
  # Applies one matchup decision: updates both Elo ratings and records the vote,
  # all in a single transaction. Returns the created Vote.
  module RecordMatchup
    module_function

    def call(winner:, loser:, voter_id:)
      new_winner_elo, new_loser_elo = Elo.updated_ratings(winner.elo, loser.elo)

      Restaurants::Restaurant.transaction do
        winner.update!(elo: new_winner_elo, matches_count: winner.matches_count + 1)
        loser.update!(elo: new_loser_elo, matches_count: loser.matches_count + 1)
        Restaurants::Vote.create!(voter_id: voter_id, winner_id: winner.id, loser_id: loser.id)
      end
    end
  end
end
