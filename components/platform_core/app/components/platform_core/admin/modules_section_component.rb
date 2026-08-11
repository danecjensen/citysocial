module PlatformCore
  module Admin
    # The "Modules" section of the single-page admin dashboard: the on/off
    # switches for every app-module in the catalog.
    class ModulesSectionComponent < ViewComponent::Base
      def modules
        @modules ||= PlatformCore::Modules.all
      end
    end
  end
end
