module PlatformCore
  # Every module's controllers inherit from this, NOT from the host's
  # ApplicationController. This keeps shared request concerns (current_user,
  # authz, layout) in the kernel where all modules can rely on them.
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception
    layout "layouts/application"

    # Every module controller inherits this, so gate disabled modules here in one
    # place. The kernel ("platform_core") is never toggleable.
    before_action :set_sentry_request_context
    before_action :ensure_module_enabled

    helper_method :current_user, :logged_in?, :admin?

    def current_user
      @current_user ||= PlatformCore::User.find_by(id: session[:user_id])
    end

    def logged_in?
      current_user.present?
    end

    def admin?
      current_user&.admin?
    end

    # Modules opt into authentication with `before_action :require_login`.
    def require_login
      return if logged_in?

      redirect_to "/login", alert: "Please log in to continue."
    end

    # Gate admin-only surfaces with `before_action :require_admin`.
    def require_admin
      return if admin?

      if logged_in?
        redirect_to "/", alert: "You do not have access to that area."
      else
        redirect_to "/login", alert: "Please log in to continue."
      end
    end

    def login(user)
      reset_session
      session[:user_id] = user.id
      @current_user = user
      apply_sentry_user(user)
    end

    def logout
      reset_session
      @current_user = nil
      apply_sentry_user(nil)
    end

    private

    def set_sentry_request_context
      return unless Sentry.initialized?

      user = current_user
      apply_sentry_user(user)
      Sentry.set_tags(
        app_module: current_module_key,
        authentication: user ? "session" : "anonymous"
      )
      Sentry.set_context("request", request_id: request.request_id)
    end

    def apply_sentry_user(user)
      return unless Sentry.initialized?

      Sentry.set_user(user ? { id: user.id.to_s } : {})
    end

    # The module a controller belongs to is its top-level namespace, e.g.
    # Marketplace::ListingsController => "marketplace". If that module is
    # toggled off, its whole surface (including its admin) is unavailable.
    def current_module_key
      self.class.name.split("::").first.underscore
    end

    def ensure_module_enabled
      return if PlatformCore::Modules.enabled?(current_module_key)

      redirect_to "/", alert: "That section is currently unavailable."
    end
  end
end
