module Restaurants
  class Restaurant < ApplicationRecord
    # A restaurant can have one or more photos. The first attached photo is the
    # representative "hero" shot shown in matchups and the leaderboard. Admins
    # can add more through the admin area; seeds attach a curated hero image.
    has_many_attached :photos

    validates :name, presence: true, uniqueness: { case_sensitive: false }

    scope :ranked, -> { order(elo: :desc, name: :asc) }

    # Narrow the board to a single cuisine. A blank cuisine is a no-op so the
    # controller can pass the (optionally nil) filter straight through.
    scope :by_cuisine, ->(cuisine) { cuisine.present? ? where(cuisine: cuisine) : all }

    # The distinct cuisines actually present in the catalog, sorted for a stable
    # filter list. Used to populate the leaderboard's cuisine select.
    def self.cuisines
      where.not(cuisine: [nil, ""]).distinct.order(:cuisine).pluck(:cuisine)
    end

    # Two distinct restaurants to compare. Returns nil when there aren't enough
    # restaurants to form a matchup yet. Photos are eager-loaded so the matchup
    # view doesn't fire N+1 queries when rendering hero images.
    def self.random_pair
      pair = with_attached_photos.order(Arel.sql("RANDOM()")).limit(2).to_a
      pair.size == 2 ? pair : nil
    end

    # The representative image for this restaurant, or nil when none is attached.
    # Admins pin one via `hero_photo_id` (an ActiveStorage attachment id); with
    # nothing pinned -- or when the pinned photo has since been removed -- the
    # oldest attachment stands in.
    def hero_photo
      attached = photos.attachments
      return nil if attached.empty?

      attached.detect { |photo| photo.id == hero_photo_id } || attached.min_by(&:id)
    end

    def hero_photo?(photo)
      hero_photo&.id == photo.id
    end
  end
end
