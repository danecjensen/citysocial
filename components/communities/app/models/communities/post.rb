module Communities
  class Post < ApplicationRecord
    include Communities::Votable

    belongs_to :community, class_name: "Communities::Community", counter_cache: :posts_count
    has_many :comments, class_name: "Communities::Comment", dependent: :destroy

    enum :kind, { text: 0, link: 1 }

    validates :title, presence: true, length: { minimum: 3, maximum: 300 }
    validates :body, length: { maximum: 40_000 }, allow_blank: true
    validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" },
                    allow_blank: true

    before_validation :infer_kind
    after_create :auto_upvote
    after_create_commit :announce_creation

    scope :hot, -> { order(pinned: :desc, score: :desc, created_at: :desc) }
    scope :recent, -> { order(created_at: :desc) }

    def author
      PlatformCore::Graph.user(author_id)
    end

    private

    def infer_kind
      self.kind = url.present? ? :link : :text
    end

    def auto_upvote
      cast_vote(author_id, 1)
    end

    def announce_creation
      PlatformCore::EventBus.publish("communities.post_created",
                                     post_id: id, community_id: community_id, author_id: author_id)
    end
  end
end
