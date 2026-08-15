module Feed
  class CommentsController < PlatformCore::BaseController
    before_action :require_login

    def create
      post = Feed::Post.find(params[:post_id])
      result = Feed::CreateComment.call(post: post, author_id: current_user.id, body: comment_params[:body])
      if result.success?
        redirect_to post_path(post, anchor: "comments"), notice: "Comment added."
      else
        redirect_to post_path(post, anchor: "comments"), alert: result.errors.to_sentence
      end
    end

    private

    def comment_params
      params.require(:comment).permit(:body)
    end
  end
end
