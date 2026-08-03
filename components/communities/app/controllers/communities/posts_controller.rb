module Communities
  class PostsController < PlatformCore::BaseController
    before_action :require_login, only: %i[new create upvote downvote]
    before_action :set_community
    before_action :set_post, only: %i[show upvote downvote]

    def show
      @comments = @post.comments.chronological
    end

    def new
      @post = @community.posts.new
    end

    def create
      @post = @community.posts.new(post_params)
      @post.author_id = current_user.id
      if @post.save
        redirect_to community_post_path(@community, @post), notice: "Posted."
      else
        render :new, status: :unprocessable_content
      end
    end

    def upvote
      @post.cast_vote(current_user.id, 1)
      redirect_back_or_to(community_post_path(@community, @post))
    end

    def downvote
      @post.cast_vote(current_user.id, -1)
      redirect_back_or_to(community_post_path(@community, @post))
    end

    private

    def set_community
      @community = Communities::Community.find_by!(slug: params[:community_slug])
    end

    def set_post
      @post = @community.posts.find(params[:id])
    end

    def post_params
      params.require(:post).permit(:title, :body, :url, :kind)
    end
  end
end
