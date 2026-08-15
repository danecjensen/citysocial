module Feed
  class PollOption < ApplicationRecord
    belongs_to :post, class_name: "Feed::Post", inverse_of: :poll_options
    has_many :poll_votes, class_name: "Feed::PollVote", dependent: :destroy, inverse_of: :poll_option

    validates :label, presence: true, length: { maximum: 120 }
  end
end
