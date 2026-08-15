module Feed
  module ReactToPost
    module_function

    def call(post:, user_id:, kind:)
      requested_kind = kind.to_s
      return :invalid unless requested_kind.in?(Feed::Reaction::KINDS)

      state = nil
      post.with_lock do
        reaction = post.reactions.find_by(user_id: user_id)
        if reaction&.kind == requested_kind
          reaction.destroy!
          state = :removed
        elsif reaction
          reaction.update!(kind: requested_kind)
          state = :changed
        else
          post.reactions.create!(user_id: user_id, kind: requested_kind)
          state = :added
        end
      end

      PlatformCore::EventBus.publish(
        "feed.reaction_changed",
        post_id: post.id,
        user_id: user_id,
        kind: requested_kind,
        state: state,
        post_author_id: post.author_id
      )
      state
    end
  end
end
