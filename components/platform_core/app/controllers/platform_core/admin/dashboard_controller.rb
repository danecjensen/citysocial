module PlatformCore
  module Admin
    # The whole admin area is this one page. Sections come from
    # PlatformCore::AdminSections, which modules populate themselves.
    class DashboardController < BaseController
      before_action :require_login
      before_action :require_admin

      def show
        @sections = PlatformCore::AdminSections.all
      end
    end
  end
end
