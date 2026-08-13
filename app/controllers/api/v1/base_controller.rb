module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_token

      private

      attr_reader :api_credential

      def authenticate_api_token
        @api_credential = PlatformCore::ApiTokens.authenticate(bearer_token)
        return if @api_credential

        response.set_header("WWW-Authenticate", 'Bearer realm="CitySocial ingestion API"')
        render json: { error: "unauthorized" }, status: :unauthorized
      end

      def bearer_token
        authorization = request.authorization.to_s
        match = authorization.match(/\ABearer\s+(?<token>\S+)\z/i)
        match&.[](:token)
      end
    end
  end
end
