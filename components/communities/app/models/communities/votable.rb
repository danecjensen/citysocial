module Communities
  # Shared up/down voting for posts and comments. A user has at most one vote per
  # votable; casting the same value again toggles it off. The votable's cached
  # `score` column is kept in sync with the sum of its votes.
  module Votable
    extend ActiveSupport::Concern

    included do
      has_many :votes, as: :votable, class_name: "Communities::Vote", dependent: :destroy
    end

    # value must be 1 (up) or -1 (down).
    def cast_vote(user_id, value)
      vote = votes.find_or_initialize_by(user_id: user_id)
      if vote.persisted? && vote.value == value
        vote.destroy
      else
        vote.value = value
        vote.save!
      end
      update_column(:score, votes.sum(:value))
    end

    def vote_value_for(user_id)
      return 0 unless user_id

      votes.find_by(user_id: user_id)&.value || 0
    end
  end
end
