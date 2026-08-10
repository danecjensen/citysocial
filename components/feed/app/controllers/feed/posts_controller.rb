module Feed
  class PostsController < PlatformCore::BaseController
    before_action :require_login

    def index
      @posts = Feed::Timeline.for_user(current_user&.id)
      @new_post = Feed::Post.new
    end

    def create
      @new_post = Feed::Post.new(author_id: current_user.id, body: post_params[:body])
      if @new_post.save
        redirect_to posts_path, notice: "Your post is live."
      else
        @posts = Feed::Timeline.for_user(current_user&.id)
        flash.now[:alert] = "Your post couldn't be shared."
        render :index, status: :unprocessable_content
      end
    end

    private

    def post_params
      params.require(:post).permit(:body)
    end
  end
end
