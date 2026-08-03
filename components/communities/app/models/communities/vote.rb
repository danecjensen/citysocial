module Communities
  class Vote < ApplicationRecord
    belongs_to :votable, polymorphic: true

    validates :value, inclusion: { in: [-1, 1] }
    validates :user_id, presence: true, uniqueness: { scope: %i[votable_type votable_id] }

    def user
      PlatformCore::Graph.user(user_id)
    end
  end
end
