module PlatformCore
  module Admin
    # Turn app-modules on and off at runtime. Disabling a module removes it from
    # navigation and blocks its routes (enforced in BaseController#ensure_module_enabled).
    class ModulesController < BaseController
      before_action :require_login
      before_action :require_admin

      def index
        @modules = PlatformCore::Modules.all
      end

      def update
        enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])
        PlatformCore::Modules.set(params[:key], enabled)
        state = enabled ? "enabled" : "disabled"
        redirect_to "/admin/modules", notice: "#{params[:key].titleize} #{state}."
      end
    end
  end
end
