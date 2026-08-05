module Restaurants
  class Restaurant < ApplicationRecord
    # A restaurant can have one or more photos. The first attached photo is the
    # representative "hero" shot shown in matchups and the leaderboard. Admins
    # can add more through the admin area; seeds attach a curated hero image.
    has_many_attached :photos

    validates :name, presence: true, uniqueness: { case_sensitive: false }

    scope :ranked, -> { order(elo: :desc, name: :asc) }

    # Two distinct restaurants to compare. Returns nil when there aren't enough
    # restaurants to form a matchup yet. Photos are eager-loaded so the matchup
    # view doesn't fire N+1 queries when rendering hero images.
    def self.random_pair
      pair = with_attached_photos.order(Arel.sql("RANDOM()")).limit(2).to_a
      pair.size == 2 ? pair : nil
    end

    # The representative image for this restaurant, or nil when none is attached.
    def hero_photo
      photos.attached? ? photos.first : nil
    end
  end
end
