module PlatformCore
  # The kernel's PUBLIC api. Other modules call PlatformCore::Graph.*,
  # never the models directly. This is the contract Packwerk privacy enforces.
  module Graph
    PublicProfile = Data.define(:id, :handle, :display_name, :neighborhood, :bio, :avatar_attached)

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

    # A PII-safe identity snapshot for sibling modules and integrations.
    def public_profile(id)
      user = PlatformCore::User.find_by(id: id)
      return unless user

      public_profile_snapshot(user)
    end

    def public_profile_by_handle(handle)
      user = PlatformCore::User.find_by(handle: handle.to_s)
      return unless user

      public_profile_snapshot(user)
    end

    def public_profile_snapshot(user)
      PublicProfile.new(
        id: user.id,
        handle: user.handle,
        display_name: user.display_name,
        neighborhood: user.neighborhood,
        bio: user.bio,
        avatar_attached: user.avatar.attached?
      )
    end
    private_class_method :public_profile_snapshot
  end
end
