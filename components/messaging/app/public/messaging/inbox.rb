module Messaging
  # Public, read-only inbox API for shell badges and event subscribers.
  module Inbox
    module_function

    def unread_count(user_id)
      Message.joins(:conversation)
             .merge(Conversation.for_participant(user_id))
             .where(read_at: nil)
             .where.not(sender_id: user_id)
             .count
    end
  end
end
