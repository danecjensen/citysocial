module Events
  # All cross-module wiring for Events lives here: what it listens for, and (by
  # convention) what it publishes. Named `Wiring` rather than the generator's
  # default `Events` because this module is *itself* named "events" — a nested
  # `Events::Events` would shadow the top-level namespace for every file inside
  # `module Events`, breaking plain `Events::Event` constant lookups.
  module Wiring
    module_function

    def subscribe!
      # Events is a publisher only for now; it subscribes to nothing.
    end

    # Events this module PUBLISHES (documented for discoverability):
    #   - "events.events_ingested" (created:, updated:)
    #       fired by Events::Ingest after a feed run writes at least one row.
  end
end
