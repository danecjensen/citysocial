module Feed
  class Post < ApplicationRecord
    validates :author_id, :body, presence: true

    # Reference the kernel's identity via its PUBLIC api, never the model.
    def author
      PlatformCore::Graph.user(author_id)
    end

    # Cross-module communication: announce, don't call. Other modules
    # (notifications, etc.) subscribe to this -- feed doesn't know they exist.
    after_create_commit do
      PlatformCore::EventBus.publish("feed.post_created", post_id: id, author_id: author_id)
    end
  end
end
