module PlatformCore
  # Every module's controllers inherit from this, NOT from the host's
  # ApplicationController. This keeps shared request concerns (current_user,
  # authz, layout) in the kernel where all modules can rely on them.
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception
    layout "layouts/application"

    helper_method :current_user, :logged_in?

    def current_user
      @current_user ||= PlatformCore::User.find_by(id: session[:user_id])
    end

    def logged_in?
      current_user.present?
    end

    # Modules opt into authentication with `before_action :require_login`.
    def require_login
      return if logged_in?

      redirect_to "/login", alert: "Please log in to continue."
    end

    def login(user)
      reset_session
      session[:user_id] = user.id
      @current_user = user
    end

    def logout
      reset_session
      @current_user = nil
    end
  end
end
