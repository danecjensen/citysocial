module Restaurants
  class Restaurant < ApplicationRecord
    validates :name, presence: true, uniqueness: { case_sensitive: false }

    scope :ranked, -> { order(elo: :desc, name: :asc) }

    # Two distinct restaurants to compare. Returns nil when there aren't enough
    # restaurants to form a matchup yet.
    def self.random_pair
      pair = order(Arel.sql("RANDOM()")).limit(2).to_a
      pair.size == 2 ? pair : nil
    end
  end
end
