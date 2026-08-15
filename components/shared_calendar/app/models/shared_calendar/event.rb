module SharedCalendar
  class Event < ApplicationRecord
    CATEGORIES = {
      "music" => ["Music", "♫"],
      "food_drink" => ["Food & drink", "✦"],
      "arts_culture" => ["Arts & culture", "◆"],
      "sports_outdoors" => ["Sports & outdoors", "●"],
      "community" => ["Community", "◎"],
      "family" => ["Family", "★"],
      "other" => ["Other", "◇"]
    }.freeze

    IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
    IMAGE_MAX_SIZE = 10.megabytes

    has_one_attached :image

    validates :title, presence: true, length: { maximum: 160 }
    validates :description, length: { maximum: 5_000 }
    validates :category, presence: true, inclusion: { in: CATEGORIES.keys }
    validates :starts_at, presence: true
    validates :venue_name, length: { maximum: 160 }
    validates :location, length: { maximum: 240 }
    validate :end_follows_start
    validate :acceptable_image

    normalizes :title, :description, :venue_name, :location, with: ->(value) { value&.strip.presence }

    scope :chronological, -> { order(:starts_at, :id) }
    scope :during, ->(range) { where(starts_at: range) }

    after_create_commit :announce_creation

    def author
      PlatformCore::Graph.user(author_id)
    end

    def category_label
      CATEGORIES.fetch(category, CATEGORIES.fetch("other")).first
    end

    def category_symbol
      CATEGORIES.fetch(category, CATEGORIES.fetch("other")).last
    end

    private

    def end_follows_start
      return if starts_at.blank? || ends_at.blank? || ends_at > starts_at

      errors.add(:ends_at, "must be after the start time")
    end

    def acceptable_image
      return unless image.attached?

      errors.add(:image, "must be a JPEG, PNG, or WebP image") unless image.blob.content_type.in?(IMAGE_CONTENT_TYPES)
      errors.add(:image, "must be smaller than 10 MB") if image.blob.byte_size > IMAGE_MAX_SIZE
    end

    def announce_creation
      PlatformCore::EventBus.publish(
        "shared_calendar.event_created",
        event_id: id,
        author_id: author_id,
        target_path: "/shared_calendar/#{id}",
        media_blob_ids: image.attached? ? [image.blob.id] : [],
        media_count: image.attached? ? 1 : 0
      )
    end
  end
end
