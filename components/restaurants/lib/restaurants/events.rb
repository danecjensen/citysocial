module Restaurants
  # All cross-module wiring for Restaurants lives here: what it listens
  # for, and (by convention) what it publishes. Keep this file as the honest
  # description of how this module connects to the rest of the system.
  module Events
    module_function

    def subscribe!
      # Restaurants reacts to nothing right now.
    end

    # Events this module PUBLISHES (documented for discoverability):
    #   - "restaurants.matchup_decided"
    #     { vote_id:, voter_id:, winner_id:, loser_id: }
    #     -> emitted by Restaurants::Vote after_create_commit when a user picks
    #        the better of two restaurants. No subscribers yet (no feed display).
  end
end
