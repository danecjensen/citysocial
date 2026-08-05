module PlatformCore
  class ProfilesController < BaseController
    before_action :require_login, only: %i[edit update]

    def show
      @user = PlatformCore::User.find_by!(handle: params[:handle])
    end

    def edit
      @user = current_user
    end

    def update
      @user = current_user
      @user.assign_attributes(profile_params)
      changed_fields = @user.changes.keys & PlatformCore::User::PUBLIC_PROFILE_FIELDS
      changed_fields << "avatar" if profile_params[:avatar].present?

      if @user.save
        publish_profile_updated(changed_fields)
        redirect_to profile_path(@user.handle), notice: "Your public profile has been updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def profile_params
      params.require(:user).permit(:display_name, :neighborhood, :bio, :avatar)
    end

    def publish_profile_updated(changed_fields)
      return if changed_fields.empty?

      PlatformCore::EventBus.publish(
        "platform_core.profile_updated",
        user_id: @user.id,
        changed_fields: changed_fields.uniq.sort
      )
    end
  end
end
