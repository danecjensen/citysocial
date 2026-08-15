module Feed
  class PollVotesController < PlatformCore::BaseController
    before_action :require_login

    def create
      post = Feed::Post.find(params[:post_id])
      option = post.poll_options.find(params[:option_id])
      state = Feed::CastPollVote.call(post: post, option: option, user_id: current_user.id)
      redirect_back_or_to post_path(post), alert: ("That poll choice is unavailable." if state == :invalid)
    end
  end
end
