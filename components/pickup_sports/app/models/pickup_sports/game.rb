module PickupSports
  class Game < ApplicationRecord
    class ParticipationError < StandardError; end

    SPORTS = %w[basketball pickleball soccer tennis ultimate volleyball].freeze
    SKILL_LEVELS = %w[all_levels beginner intermediate advanced].freeze
    STATUSES = %w[open completed canceled].freeze

    has_many :roster_entries, class_name: "PickupSports::RosterEntry", dependent: :destroy, inverse_of: :game

    validates :host_id, :title, :sport, :skill_level, :neighborhood, :venue, :starts_at, :capacity, presence: true
    validates :title, length: { maximum: 100 }
    validates :neighborhood, :venue, length: { maximum: 80 }
    validates :details, length: { maximum: 1000 }, allow_blank: true
    validates :sport, inclusion: { in: SPORTS }
    validates :skill_level, inclusion: { in: SKILL_LEVELS }
    validates :status, inclusion: { in: STATUSES }
    validates :capacity, numericality: { only_integer: true, in: 2..100 }
    validate :starts_in_the_future, if: -> { new_record? || will_save_change_to_starts_at? }

    scope :upcoming, -> { where(status: "open").where(starts_at: Time.current..).order(:starts_at, :id) }
    scope :by_sport, ->(sport) { where(sport: sport) }
    scope :in_neighborhood, lambda { |query|
      pattern = "%#{sanitize_sql_like(query.to_s.strip)}%"
      where("neighborhood ILIKE ?", pattern)
    }
    scope :on_date, ->(date) { where(starts_at: date.in_time_zone.all_day) }

    after_create :seat_host
    after_create_commit :announce_creation
    after_update_commit :announce_cancellation, if: :canceled_now?
    after_update_commit :announce_attendance_closeout, if: :completed_now?

    def host
      PlatformCore::Graph.user(host_id)
    end

    def open?
      status == "open"
    end

    def canceled?
      status == "canceled"
    end

    def completed?
      status == "completed"
    end

    def started?
      starts_at <= Time.current
    end

    def joined_count
      return roster_entries.count(&:committed?) if roster_entries.loaded?

      roster_entries.committed.count
    end

    def waitlisted_count
      return roster_entries.count(&:waitlisted?) if roster_entries.loaded?

      roster_entries.waitlisted.count
    end

    def seats_remaining
      [capacity - joined_count, 0].max
    end

    def full?
      seats_remaining.zero?
    end

    def joinable?
      open? && starts_at.future?
    end

    def attendance_recordable?
      started? && (open? || completed?)
    end

    def pending_attendance_count
      roster_entries.joined.count
    end

    def attendance_ready_to_close?
      attendance_recordable? && open? && pending_attendance_count.zero?
    end

    def entry_for(resident_id)
      roster_entries.find_by(resident_id: resident_id)
    end

    def join!(resident_id)
      raise ParticipationError, "This game is no longer accepting players." unless joinable?

      with_lock do
        existing = entry_for(resident_id)
        next existing if existing

        roster_entries.create!(
          resident_id: resident_id,
          status: roster_entries.joined.count < capacity ? "joined" : "waitlisted"
        )
      end
    end

    def leave!(resident_id)
      raise ParticipationError, "Hosts stay on the roster; cancel the game instead." if resident_id == host_id

      promoted = nil
      transaction do
        with_lock do
          entry = roster_entries.lock.find_by(resident_id: resident_id)
          next unless entry

          joined = entry.joined?
          entry.destroy!
          if joined && joinable?
            promoted = roster_entries.waitlisted.order(:created_at, :id).lock.first
            promoted&.update!(status: "joined")
          end
        end
      end
      promoted
    end

    def cancel!
      raise ParticipationError, "Completed games keep their attendance record." if completed?

      update!(status: "canceled")
    end

    def close_attendance!
      raise ParticipationError, "Attendance can be recorded after the game starts." unless started?
      raise ParticipationError, "Canceled games cannot be closed out." if canceled?
      return self if completed?
      unless pending_attendance_count.zero?
        raise ParticipationError, "Mark every player attended or absent before closing attendance."
      end

      update!(status: "completed")
      self
    end

    private

    def seat_host
      roster_entries.create!(resident_id: host_id, status: "joined")
    end

    def starts_in_the_future
      errors.add(:starts_at, "must be in the future") if starts_at.present? && !starts_at.future?
    end

    def canceled_now?
      saved_change_to_status? && canceled?
    end

    def completed_now?
      saved_change_to_status? && completed?
    end

    def announce_creation
      PlatformCore::EventBus.publish(
        "pickup_sports.game_created",
        game_id: id,
        host_id: host_id,
        target_path: "/pickup_sports/games/#{id}"
      )
    end

    def announce_cancellation
      PlatformCore::EventBus.publish(
        "pickup_sports.game_changed",
        game_id: id,
        actor_id: host_id,
        change_kind: "canceled",
        target_path: "/pickup_sports/games/#{id}"
      )
    end

    def announce_attendance_closeout
      PlatformCore::EventBus.publish(
        "pickup_sports.game_changed",
        game_id: id,
        actor_id: host_id,
        change_kind: "attendance_closed",
        target_path: "/pickup_sports/games/#{id}"
      )
    end
  end
end
