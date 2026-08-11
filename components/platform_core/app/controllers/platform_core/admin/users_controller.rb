module PlatformCore
  module Admin
    # Actions behind the "Users" section of the /admin page. Every path leads
    # back to that one page, anchored at the section that was acted on.
    class UsersController < BaseController
      SECTION = "/admin#section-users".freeze

      before_action :require_login
      before_action :require_admin
      before_action :set_user, only: %i[update destroy]

      def update
        @user.update(admin: ActiveModel::Type::Boolean.new.cast(params[:admin]))
        redirect_to SECTION, notice: "Updated @#{@user.handle}."
      end

      def destroy
        if @user == current_user
          redirect_to SECTION, alert: "You cannot delete your own account."
        else
          @user.destroy
          redirect_to SECTION, notice: "Deleted @#{@user.handle}."
        end
      end

      private

      def set_user
        @user = PlatformCore::User.find(params[:id])
      end
    end
  end
end
