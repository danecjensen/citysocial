module PlatformCore
  module Admin
    # The "Users" section of the single-page admin dashboard. Loads its own data
    # so the dashboard controller stays a dumb frame around the section registry.
    class UsersSectionComponent < ViewComponent::Base
      delegate :current_user, to: :helpers

      def users
        @users ||= PlatformCore::User.order(created_at: :asc)
      end
    end
  end
end
