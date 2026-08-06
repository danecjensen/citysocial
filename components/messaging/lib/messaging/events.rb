module Messaging
  # All cross-module wiring for Messaging lives here: what it listens
  # for, and (by convention) what it publishes. Keep this file as the honest
  # description of how this module connects to the rest of the system.
  module Events
    module_function

    def subscribe!
      # Messaging reacts to nothing yet. Other modules can subscribe to the
      # private-content-free event below without Messaging knowing about them.
    end

    # Events this module PUBLISHES (documented for discoverability):
    #   - "messaging.message_created"
    #     { message_id:, conversation_id:, sender_id:, recipient_id: }
    #     -> emitted after a message commits; body is intentionally excluded.
  end
end
