module PickupSports
  # All cross-module wiring for PickupSports lives here: what it listens
  # for, and (by convention) what it publishes. Keep this file as the honest
  # description of how this module connects to the rest of the system.
  module Events
    module_function

    def subscribe!
      # Milestone 1 publishes roster activity for future notification subscribers;
      # it does not consume sibling events.
    end

    # Events this module PUBLISHES (documented for discoverability):
    #   - "pickup_sports.game_created"
    #       game_id, host_id, target_path
    #   - "pickup_sports.game_changed"
    #       game_id, actor_id, change_kind, target_path
    #   - "pickup_sports.roster_changed"
    #       game_id, actor_id, host_id, roster_status, change_kind, target_path
    #   - "pickup_sports.roster_promoted"
    #       game_id, recipient_id, host_id, target_path
  end
end
