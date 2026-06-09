module PlatformCore
  # Every module's controllers inherit from this, NOT from the host's
  # ApplicationController. This keeps shared request concerns (current_user,
  # authz, layout) in the kernel where all modules can rely on them.
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception
    layout "layouts/application"

    helper_method :current_user

    def current_user
      @current_user ||= PlatformCore::User.find_by(id: session[:user_id])
    end
  end
end
