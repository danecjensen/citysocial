module PickupSports
  class RosterEntry < ApplicationRecord
    STATUSES = %w[joined waitlisted].freeze

    belongs_to :game, class_name: "PickupSports::Game", inverse_of: :roster_entries

    validates :resident_id, presence: true, uniqueness: { scope: :game_id }
    validates :status, inclusion: { in: STATUSES }

    scope :joined, -> { where(status: "joined") }
    scope :waitlisted, -> { where(status: "waitlisted") }

    after_create_commit :announce_join
    after_update_commit :announce_promotion, if: :promoted?
    after_destroy_commit :announce_leave

    def joined?
      status == "joined"
    end

    def waitlisted?
      status == "waitlisted"
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
      saved_change_to_status? && joined?
    end

    def target_path
      "/pickup_sports/games/#{game_id}"
    end
  end
end
