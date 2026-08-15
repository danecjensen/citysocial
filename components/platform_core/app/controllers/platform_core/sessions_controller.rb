module PlatformCore
  class SessionsController < BaseController
    def new
      redirect_to "/" if logged_in?
    end

    def create
      user = PlatformCore::User.find_by(email: params[:email].to_s.strip.downcase)

      if user&.authenticate(params[:password])
        login(user)
        PlatformCore::Analytics.identify(user)
        PlatformCore::Analytics.capture(
          "user logged in",
          user_id: user,
          properties: { authentication_method: "password" }
        )
        redirect_to "/", notice: "Welcome back, #{user.handle}."
      else
        flash.now[:alert] = "Invalid email or password."
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      user = current_user
      PlatformCore::Analytics.capture("user logged out", user_id: user) if user
      logout
      redirect_to "/login", notice: "Signed out."
    end
  end
end
