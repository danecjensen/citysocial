module Notifications
  # Public read API for shared shell surfaces. Callers never query the module's
  # private Notification model directly.
  module Inbox
    module_function

    def unread_count_for(user_id)
      Notifications::Notification.unread.where(recipient_id: user_id).count
    end
  end
end
