module PlatformCore
  # Completes an OAuth sign-in (Google today) after the OmniAuth middleware has
  # finished the provider handshake and populated request.env["omniauth.auth"].
  # Identity is kernel-owned, so this lives in platform_core alongside sessions.
  class OmniauthCallbacksController < BaseController
    def create
      user = PlatformCore::User.from_omniauth(request.env["omniauth.auth"])

      if user&.persisted?
        login(user)
        redirect_to "/", notice: "Signed in with Google. Welcome, #{user.handle}."
      else
        redirect_to "/login", alert: sign_in_failed_message
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      redirect_to "/login", alert: sign_in_failed_message
    end

    def failure
      redirect_to "/login", alert: "Google sign-in was canceled or didn't complete."
    end

    private

    def sign_in_failed_message
      "We couldn't sign you in with Google. Please try again."
    end
  end
end
