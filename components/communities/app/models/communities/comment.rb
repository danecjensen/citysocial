module Communities
  class Comment < ApplicationRecord
    include Communities::Votable

    belongs_to :post, class_name: "Communities::Post", counter_cache: :comments_count

    validates :body, presence: true, length: { maximum: 10_000 }

    after_create :auto_upvote

    scope :chronological, -> { order(created_at: :asc) }
    scope :top, -> { order(score: :desc, created_at: :desc) }

    def author
      PlatformCore::Graph.user(author_id)
    end

    private

    def auto_upvote
      cast_vote(author_id, 1)
    end
  end
end
