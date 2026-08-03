module Communities
  # All cross-module wiring for Communities lives here: what it listens
  # for, and (by convention) what it publishes. Keep this file as the honest
  # description of how this module connects to the rest of the system.
  module Events
    module_function

    def subscribe!
      # Communities is a publisher only for now; it subscribes to nothing.
    end

    # Events this module PUBLISHES (documented for discoverability):
    #   - "communities.community_created" (community_id:, creator_id:)
    #   - "communities.post_created"      (post_id:, community_id:, author_id:)
  end
end
