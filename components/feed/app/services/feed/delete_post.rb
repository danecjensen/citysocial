module Feed
  module DeletePost
    module_function

    def call(post:, author_id:)
      return false unless post.author_id.present? && post.author_id == author_id

      post_id = post.id
      kind = post.kind
      post.destroy!
      PlatformCore::EventBus.publish("feed.post_deleted", post_id: post_id, author_id: author_id, kind: kind)
      true
    end
  end
end
