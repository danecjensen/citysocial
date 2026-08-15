module Feed
  class PostsController < PlatformCore::BaseController
    before_action :require_login
    before_action :set_post, only: %i[show edit update destroy]
    before_action :require_owner, only: %i[edit update destroy]

    def index
      prepare_index
    end

    def show
      @comment = Feed::Comment.new
      @comments = @post.comments.includes(:post).order(:created_at, :id)
      @authors = PlatformCore::Graph.users([@post.author_id, *@comments.map(&:author_id)])
    end

    def edit; end

    def create
      attributes = post_params
      photos = attributes.delete(:photos)
      poll_options = Feed::Post::POLL_OPTION_ATTRIBUTES.map { |attribute| attributes.delete(attribute) }
      result = Feed::PublishPost.call(
        source: "web",
        author_id: current_user.id,
        photos: photos,
        poll_options: poll_options,
        **attributes.to_h.symbolize_keys
      )

      if result.success?
        redirect_to post_path(result.post), notice: "Your post is live."
      else
        @composer = result.post
        prepare_index(load_composer: false)
        flash.now[:alert] = result.errors.to_sentence
        render :index, status: :unprocessable_content
      end
    end

    def update
      attributes = post_params
      photos = attributes.delete(:photos)
      result = Feed::UpdatePost.call(
        post: @post,
        author_id: current_user.id,
        attributes: attributes,
        photos: photos
      )

      if result.success?
        redirect_to post_path(@post), notice: "Post updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      Feed::DeletePost.call(post: @post, author_id: current_user.id)
      redirect_to posts_path, notice: "Post deleted."
    end

    private

    def prepare_index(load_composer: true)
      @composer = Feed::Post.new if load_composer
      @filter = params[:filter].presence_in(%w[saved])
      @posts = Feed::Timeline.for_user(current_user.id, saved: @filter == "saved")
      @authors = PlatformCore::Graph.users(@posts.map(&:author_id))
    end

    def set_post
      @post = Feed::Post.includes(
        :reactions,
        :saves,
        :poll_votes,
        { poll_options: :poll_votes },
        { photos_attachments: :blob },
        { preview_image_attachment: :blob }
      ).find(params[:id])
    end

    def require_owner
      return if @post.author_id == current_user.id

      redirect_to post_path(@post), alert: "Only the author can change this post."
    end

    def post_params
      params.require(:post).permit(
        :kind,
        :title,
        :body,
        :url,
        :target_path,
        *Feed::Post::POLL_OPTION_ATTRIBUTES,
        photos: []
      )
    end
  end
end
