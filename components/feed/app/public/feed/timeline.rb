module Feed
  # Feed's PUBLIC api. A sibling module that needs feed data calls this.
  module Timeline
    module_function

    def for_user(user_id, limit: 50, saved: false)
      return saved_for_user(user_id, limit: limit) if saved

      author_ids = PlatformCore::Graph.following_ids(user_id) << user_id
      personal = Feed::Post.where(author_id: author_ids)
      activity = Feed::Post.where("source LIKE ?", "module:%")
      preload(personal.or(activity).order(created_at: :desc).limit(limit))
    end

    def saved_for_user(user_id, limit: 50)
      preload(Feed::Post.joins(:saves).where(feed_saves: { user_id: user_id }).order(created_at: :desc).limit(limit))
    end

    def preload(scope)
      scope.includes(
        :reactions,
        :saves,
        :poll_votes,
        { poll_options: :poll_votes },
        { photos_attachments: :blob },
        { preview_image_attachment: :blob }
      )
    end
    private_class_method :preload
  end
end
