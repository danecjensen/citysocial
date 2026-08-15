module Feed
  class ReactionsController < PlatformCore::BaseController
    before_action :require_login

    def create
      post = Feed::Post.find(params[:post_id])
      state = Feed::ReactToPost.call(post: post, user_id: current_user.id, kind: params[:kind])
      redirect_back_or_to post_path(post), alert: ("Unknown reaction." if state == :invalid)
    end
  end
end
