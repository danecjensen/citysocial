module PlatformCore
  module Admin
    # The "Users" section of the single-page admin dashboard. Loads its own data
    # so the dashboard controller stays a dumb frame around the section registry.
    class UsersSectionComponent < ViewComponent::Base
      def users
        @users ||= PlatformCore::User.order(created_at: :asc)
      end

      def current_user
        helpers.current_user
      end
    end
  end
end
