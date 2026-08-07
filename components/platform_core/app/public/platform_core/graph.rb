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

    # Batch counterpart to .user for rendering collections without an N+1.
    # Returns an id => user hash (avatars preloaded), skipping blank ids;
    # unknown ids are simply absent from the result.
    def users(ids)
      keys = Array(ids).compact_blank.uniq
      return {} if keys.empty?

      PlatformCore::User.where(id: keys).with_attached_avatar.index_by(&:id)
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

    # Public-field-only search used by modules that need resident discovery
    # without querying the kernel's User model or exposing private identity.
    def public_profile_ids_matching(query, limit: 100)
      term = query.to_s.strip
      return [] if term.blank?

      pattern = "%#{PlatformCore::User.sanitize_sql_like(term)}%"
      PlatformCore::User.where("handle ILIKE :pattern OR display_name ILIKE :pattern", pattern: pattern)
                        .limit(limit)
                        .pluck(:id)
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
