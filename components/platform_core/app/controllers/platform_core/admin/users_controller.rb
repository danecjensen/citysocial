module PlatformCore
  module Admin
    class UsersController < BaseController
      before_action :require_login
      before_action :require_admin
      before_action :set_user, only: %i[update destroy]

      def index
        @users = PlatformCore::User.order(created_at: :asc)
      end

      def update
        @user.update(admin: ActiveModel::Type::Boolean.new.cast(params[:admin]))
        redirect_to "/admin/users", notice: "Updated @#{@user.handle}."
      end

      def destroy
        if @user == current_user
          redirect_to "/admin/users", alert: "You cannot delete your own account."
        else
          @user.destroy
          redirect_to "/admin/users", notice: "Deleted @#{@user.handle}."
        end
      end

      private

      def set_user
        @user = PlatformCore::User.find(params[:id])
      end
    end
  end
end
