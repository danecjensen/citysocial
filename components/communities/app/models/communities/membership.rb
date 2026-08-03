module Communities
  class Membership < ApplicationRecord
    belongs_to :community, class_name: "Communities::Community"

    enum :role, { member: 0, moderator: 1, owner: 2 }

    validates :user_id, presence: true, uniqueness: { scope: :community_id }

    def user
      PlatformCore::Graph.user(user_id)
    end
  end
end
