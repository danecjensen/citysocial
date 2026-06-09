module PlatformCore
  class RegistrationsController < BaseController
    def new
      redirect_to "/" if logged_in?
      @user = PlatformCore::User.new
    end

    def create
      @user = PlatformCore::User.new(user_params)

      if @user.save
        login(@user)
        redirect_to "/", notice: "Welcome to CitySocial, #{@user.handle}."
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def user_params
      params.require(:user).permit(:handle, :email, :password, :password_confirmation)
    end
  end
end
