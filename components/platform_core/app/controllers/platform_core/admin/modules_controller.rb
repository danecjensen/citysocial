module PlatformCore
  module Admin
    # Turn app-modules on and off at runtime. Disabling a module removes it from
    # navigation, blocks its routes (enforced in BaseController#ensure_module_enabled),
    # and drops its section from the admin page.
    class ModulesController < BaseController
      SECTION = "/admin#section-modules".freeze

      before_action :require_login
      before_action :require_admin

      def update
        enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])
        PlatformCore::Modules.set(params[:key], enabled)
        state = enabled ? "enabled" : "disabled"
        redirect_to SECTION, notice: "#{params[:key].titleize} #{state}."
      end
    end
  end
end
