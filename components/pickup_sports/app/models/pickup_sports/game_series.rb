module PickupSports
  class GameSeries < ApplicationRecord
    MAX_OCCURRENCES = 8
    MIN_OCCURRENCES = 2

    has_many :games,
             -> { order(:series_position) },
             class_name: "PickupSports::Game",
             dependent: :restrict_with_error,
             inverse_of: :game_series

    validates :host_id, :title, :sport, :skill_level, :neighborhood, :venue, :starts_at, :capacity,
              :occurrences_count, presence: true
    validates :title, length: { maximum: 100 }
    validates :neighborhood, :venue, length: { maximum: 80 }
    validates :details, length: { maximum: 1000 }, allow_blank: true
    validates :sport, inclusion: { in: Game::SPORTS }
    validates :skill_level, inclusion: { in: Game::SKILL_LEVELS }
    validates :capacity, numericality: { only_integer: true, in: 2..100 }
    validates :occurrences_count,
              numericality: { only_integer: true, in: MIN_OCCURRENCES..MAX_OCCURRENCES }
    validate :starts_in_the_future

    after_create_commit :announce_creation

    def schedule
      return false unless valid?

      transaction do
        save!
        occurrences_count.times do |offset|
          games.create!(game_attributes.merge(starts_at: starts_at.advance(weeks: offset), series_position: offset + 1))
        end
      end
      true
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, e.record.errors.full_messages.to_sentence) unless e.record.equal?(self)
      false
    end

    private

    def game_attributes
      attributes.slice("host_id", "title", "sport", "skill_level", "neighborhood", "venue", "details", "capacity")
    end

    def starts_in_the_future
      errors.add(:starts_at, "must be in the future") if starts_at.present? && !starts_at.future?
    end

    def announce_creation
      PlatformCore::EventBus.publish(
        "pickup_sports.series_created",
        series_id: id,
        host_id: host_id,
        game_ids: games.ids,
        target_path: "/pickup_sports/series/#{id}"
      )
    end
  end
end
