module Feed
  class Comment < ApplicationRecord
    belongs_to :post, class_name: "Feed::Post", counter_cache: true, inverse_of: :comments

    validates :author_id, :body, presence: true
    validates :body, length: { maximum: 5_000 }

    def author
      PlatformCore::Graph.user(author_id)
    end
  end
end
