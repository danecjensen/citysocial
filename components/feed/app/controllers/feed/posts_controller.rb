module Feed
  class PostsController < PlatformCore::BaseController
    before_action :require_login

    def index
      @posts = Feed::Timeline.for_user(current_user&.id)
    end

    def create
      Feed::Post.create!(author_id: current_user.id, body: params[:body])
      redirect_to posts_path
    end
  end
end
