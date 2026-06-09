module Feed
  # Feed's PUBLIC api. A sibling module that needs feed data calls this.
  module Timeline
    module_function

    def for_user(user_id, limit: 50)
      author_ids = PlatformCore::Graph.following_ids(user_id) << user_id
      Feed::Post.where(author_id: author_ids).order(created_at: :desc).limit(limit)
    end
  end
end
