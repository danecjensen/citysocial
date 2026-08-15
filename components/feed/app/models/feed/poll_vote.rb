module Feed
  class PollVote < ApplicationRecord
    belongs_to :post, class_name: "Feed::Post", inverse_of: :poll_votes
    belongs_to :poll_option, class_name: "Feed::PollOption", counter_cache: :votes_count,
                             inverse_of: :poll_votes

    validates :user_id, presence: true, uniqueness: { scope: :post_id }
    validate :option_belongs_to_post

    private

    def option_belongs_to_post
      return if poll_option.nil? || post.nil? || poll_option.post_id == post.id

      errors.add(:poll_option, "must belong to this poll")
    end
  end
end
