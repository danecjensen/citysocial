module Feedback
  # All cross-module wiring for Feedback lives here: what it listens
  # for, and (by convention) what it publishes. Keep this file as the honest
  # description of how this module connects to the rest of the system.
  module Events
    module_function

    def subscribe!
      # Feedback currently consumes no cross-module events.
    end

    # Events this module PUBLISHES (documented for discoverability):
    #   - "feedback.submission_created"
    #       submission_id, author_id, kind, area
    #   - "feedback.submission_supported"
    #       submission_id, supporter_id, author_id
    #   - "feedback.submission_status_changed"
    #       submission_id, author_id, status
  end
end
