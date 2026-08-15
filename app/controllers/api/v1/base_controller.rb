module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_token
      before_action :set_sentry_request_context

      private

      attr_reader :api_credential

      def authenticate_api_token
        @api_credential = PlatformCore::ApiTokens.authenticate(bearer_token)
        return if @api_credential

        response.set_header("WWW-Authenticate", 'Bearer realm="CitySocial ingestion API"')
        render json: { error: "unauthorized" }, status: :unauthorized
      end

      def set_sentry_request_context
        return unless api_credential && Sentry.initialized?

        Sentry.set_user(id: api_credential.user_id.to_s)
        Sentry.set_tags(
          app_module: "ingestion_api",
          authentication: "api_token",
          ingestion_source: api_credential.source
        )
        Sentry.set_context(
          "api_credential",
          id: api_credential.id,
          source: api_credential.source,
          request_id: request.request_id
        )
      end

      def bearer_token
        authorization = request.authorization.to_s
        match = authorization.match(/\ABearer\s+(?<token>\S+)\z/i)
        match&.[](:token)
      end
    end
  end
end
