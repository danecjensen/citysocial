module NeighborHelp
  # All cross-module wiring for NeighborHelp lives here: what it listens
  # for, and (by convention) what it publishes. Keep this file as the honest
  # description of how this module connects to the rest of the system.
  module Events
    module_function

    def subscribe!
      # Neighbor Help owns the favor lifecycle and currently consumes no sibling events.
    end

    # Events this module PUBLISHES (documented for discoverability):
    #   - "neighbor_help.request_created"
    #     (request_id:, actor_id:, requester_id:, target_path:)
    #   - "neighbor_help.request_changed"
    #     (request_id:, actor_id:, requester_id:, helper_id:, recipient_id:,
    #      status:, change_kind:, target_path:)
    #
    # Payloads contain no title, details, logistics, contact information, or address.
  end
end
