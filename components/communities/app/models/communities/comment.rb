module Communities
  class Comment < ApplicationRecord
    include Communities::Votable

    belongs_to :post, class_name: "Communities::Post", counter_cache: :comments_count

    validates :body, presence: true, length: { maximum: 10_000 }

    after_create :auto_upvote
    after_create_commit :announce_creation

    scope :chronological, -> { order(created_at: :asc) }
    scope :top, -> { order(score: :desc, created_at: :desc) }

    def author
      PlatformCore::Graph.user(author_id)
    end

    private

    def auto_upvote
      cast_vote(author_id, 1)
    end

    def announce_creation
      PlatformCore::EventBus.publish(
        "communities.comment_created",
        comment_id: id,
        post_id: post_id,
        community_slug: post.community.slug,
        author_id: author_id,
        post_author_id: post.author_id
      )
    end
  end
end
