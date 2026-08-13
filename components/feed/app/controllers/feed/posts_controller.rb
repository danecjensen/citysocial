module Feed
  class PostsController < PlatformCore::BaseController
    before_action :require_login

    def index
      @posts = Feed::Timeline.for_user(current_user&.id)
    end

    def create
      result = Feed::PublishPost.call(source: "web", author_id: current_user.id, body: params[:body])
      if result.success?
        redirect_to posts_path
      else
        redirect_to posts_path, alert: result.errors.to_sentence
      end
    end
  end
end
