module Feed
  module CastPollVote
    module_function

    def call(post:, option:, user_id:)
      return :invalid unless post.kind == "poll" && option.post_id == post.id

      state = nil
      post.with_lock do
        vote = post.poll_votes.find_by(user_id: user_id)
        if vote&.poll_option_id == option.id
          state = :unchanged
        elsif vote
          vote.update!(poll_option: option)
          state = :changed
        else
          post.poll_votes.create!(poll_option: option, user_id: user_id)
          state = :voted
        end
      end

      unless state == :unchanged
        PlatformCore::EventBus.publish(
          "feed.poll_voted",
          post_id: post.id,
          poll_option_id: option.id,
          user_id: user_id,
          state: state
        )
      end
      state
    end
  end
end
