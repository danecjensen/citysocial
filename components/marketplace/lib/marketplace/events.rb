module Marketplace
  # All cross-module wiring for Marketplace lives here: what it listens
  # for, and (by convention) what it publishes. Keep this file as the honest
  # description of how this module connects to the rest of the system.
  module Events
    module_function

    def subscribe!
      # Marketplace is a publisher only for now; it subscribes to nothing.
    end

    # Events this module PUBLISHES (documented for discoverability):
    #   - "marketplace.listing_created" (listing_id:, author_id:)
    #   - "marketplace.listing_sold"    (listing_id:, author_id:)
  end
end
