module Api
  module V1
    class PostsController < BaseController
      def create
        if post_params[:external_id].blank?
          return render json: { status: :invalid, errors: ["external ID can't be blank"] },
                        status: :unprocessable_content
        end

        result = Feed::PublishPost.call(
          source: api_credential.source,
          author_id: api_credential.user_id,
          **post_params.to_h.symbolize_keys
        )

        render_result(result)
      end

      private

      def post_params
        params.permit(:external_id, :title, :url, :body)
      end

      def render_result(result)
        if result.success?
          render json: {
            status: result.status,
            post: { id: result.post.id, source: result.post.source, external_id: result.post.external_id }
          }, status: result.status == :created ? :created : :ok
        else
          render json: { status: result.status, errors: result.errors }, status: :unprocessable_content
        end
      end
    end
  end
end
