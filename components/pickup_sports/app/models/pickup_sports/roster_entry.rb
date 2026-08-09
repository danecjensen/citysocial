module PickupSports
  class RosterEntry < ApplicationRecord
    ATTENDANCE_STATUSES = %w[attended absent].freeze
    COMMITTED_STATUSES = %w[joined attended absent].freeze
    STATUSES = (COMMITTED_STATUSES + %w[waitlisted]).freeze

    belongs_to :game, class_name: "PickupSports::Game", inverse_of: :roster_entries

    validates :resident_id, presence: true, uniqueness: { scope: :game_id }
    validates :status, inclusion: { in: STATUSES }

    scope :joined, -> { where(status: "joined") }
    scope :committed, -> { where(status: COMMITTED_STATUSES) }
    scope :waitlisted, -> { where(status: "waitlisted") }

    after_create_commit :announce_join
    after_update_commit :announce_promotion, if: :promoted?
    after_update_commit :announce_attendance, if: :attendance_changed?
    after_destroy_commit :announce_leave

    def joined?
      status == "joined"
    end

    def waitlisted?
      status == "waitlisted"
    end

    def attended?
      status == "attended"
    end

    def absent?
      status == "absent"
    end

    def committed?
      COMMITTED_STATUSES.include?(status)
    end

    def record_attendance!(attendance_status)
      attendance_status = attendance_status.to_s
      unless ATTENDANCE_STATUSES.include?(attendance_status)
        raise Game::ParticipationError, "Choose attended or absent."
      end
      unless game.attendance_recordable?
        raise Game::ParticipationError, "Attendance can be recorded after the game starts."
      end
      raise Game::ParticipationError, "Waitlisted residents were not rostered for this game." if waitlisted?

      update!(status: attendance_status)
      self
    end

    private

    def announce_join
      PlatformCore::EventBus.publish(
        "pickup_sports.roster_changed",
        game_id: game_id,
        actor_id: resident_id,
        host_id: game.host_id,
        roster_status: status,
        change_kind: "joined",
        target_path: target_path
      )
    end

    def announce_promotion
      PlatformCore::EventBus.publish(
        "pickup_sports.roster_promoted",
        game_id: game_id,
        recipient_id: resident_id,
        host_id: game.host_id,
        target_path: target_path
      )
    end

    def announce_leave
      PlatformCore::EventBus.publish(
        "pickup_sports.roster_changed",
        game_id: game_id,
        actor_id: resident_id,
        host_id: game.host_id,
        roster_status: status,
        change_kind: "left",
        target_path: target_path
      )
    end

    def promoted?
      saved_change_to_status? && status == "joined"
    end

    def attendance_changed?
      saved_change_to_status? && ATTENDANCE_STATUSES.include?(status)
    end

    def announce_attendance
      previous_status = saved_change_to_status.first
      PlatformCore::EventBus.publish(
        "pickup_sports.attendance_recorded",
        game_id: game_id,
        roster_entry_id: id,
        recipient_id: resident_id,
        actor_id: game.host_id,
        attendance_status: status,
        change_kind: ATTENDANCE_STATUSES.include?(previous_status) ? "corrected" : "recorded",
        target_path: target_path
      )
    end

    def target_path
      "/pickup_sports/games/#{game_id}"
    end
  end
end
