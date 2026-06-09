module Restaurants
  # Standard Elo rating math. Pure functions — no persistence.
  module Elo
    K = 32

    module_function

    # Given the current ratings, returns [new_winner, new_loser] as integers.
    def updated_ratings(winner_rating, loser_rating)
      expected_winner = 1.0 / (1.0 + (10**((loser_rating - winner_rating) / 400.0)))
      new_winner = winner_rating + (K * (1 - expected_winner))
      new_loser = loser_rating + (K * (expected_winner - 1))
      [new_winner.round, new_loser.round]
    end
  end
end
