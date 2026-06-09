module PlatformCore
  # The kernel's PUBLIC api. Other modules call PlatformCore::Graph.*,
  # never the models directly. This is the contract Packwerk privacy enforces.
  module Graph
    module_function

    def follower_ids(user_id)
      PlatformCore::Follow.where(followed_id: user_id).pluck(:follower_id)
    end

    def following_ids(user_id)
      PlatformCore::Follow.where(follower_id: user_id).pluck(:followed_id)
    end

    def user(id)
      PlatformCore::User.find_by(id: id)
    end
  end
end
