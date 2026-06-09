module PlatformCore
  # The social graph edge. This is the one piece of cross-cutting state every
  # social module (feed, messaging, ...) reads. It lives in the kernel.
  class Follow < ApplicationRecord
    belongs_to :follower, class_name: "PlatformCore::User"
    belongs_to :followed, class_name: "PlatformCore::User"
    validates :follower_id, uniqueness: { scope: :followed_id }
  end
end
