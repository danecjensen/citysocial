module Feed
  class SavesController < PlatformCore::BaseController
    before_action :require_login

    def create
      toggle
    end

    def destroy
      toggle
    end

    private

    def toggle
      post = Feed::Post.find(params[:post_id])
      Feed::ToggleSave.call(post: post, user_id: current_user.id)
      redirect_back_or_to post_path(post)
    end
  end
end
