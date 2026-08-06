module Notifications
  class NotificationsController < PlatformCore::BaseController
    before_action :require_login
    before_action :set_notification, only: :read

    def index
      @notifications = Notification.where(recipient_id: current_user.id).recent.limit(100)
    end

    def read
      @notification.mark_read!
      redirect_to @notification.target_path
    end

    def read_all
      now = Time.current
      Notification.where(recipient_id: current_user.id).unread.update_all(read_at: now, updated_at: now)
      redirect_to root_path, notice: "Notifications marked as read."
    end

    private

    def set_notification
      @notification = Notification.where(recipient_id: current_user.id).find(params[:id])
    end
  end
end
