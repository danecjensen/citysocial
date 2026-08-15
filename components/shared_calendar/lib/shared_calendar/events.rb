module SharedCalendar
  # All cross-module wiring for SharedCalendar lives here: what it listens
  # for, and (by convention) what it publishes. Keep this file as the honest
  # description of how this module connects to the rest of the system.
  module Events
    module_function

    def subscribe!
      # SharedCalendar is a publisher only for now; it subscribes to nothing.
    end

    # Events this module PUBLISHES (documented for discoverability):
    #   - "shared_calendar.event_created" (event_id:, author_id:)
  end
end
