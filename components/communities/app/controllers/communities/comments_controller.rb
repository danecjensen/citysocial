module Communities
  class CommentsController < PlatformCore::BaseController
    before_action :require_login
    before_action :set_post
    before_action :set_comment, only: %i[upvote downvote]

    def create
      comment = @post.comments.new(comment_params)
      comment.author_id = current_user.id
      if comment.save
        redirect_to community_post_path(@community, @post, anchor: "comment-#{comment.id}"), notice: "Comment added."
      else
        redirect_to community_post_path(@community, @post), alert: comment.errors.full_messages.to_sentence
      end
    end

    def upvote
      @comment.cast_vote(current_user.id, 1)
      redirect_back_or_to(community_post_path(@community, @post))
    end

    def downvote
      @comment.cast_vote(current_user.id, -1)
      redirect_back_or_to(community_post_path(@community, @post))
    end

    private

    def set_post
      @community = Communities::Community.find_by!(slug: params[:community_slug])
      @post = @community.posts.find(params[:post_id])
    end

    def set_comment
      @comment = @post.comments.find(params[:id])
    end

    def comment_params
      params.require(:comment).permit(:body)
    end
  end
end
