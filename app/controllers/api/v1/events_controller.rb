module Api
  module V1
    class EventsController < BaseController
      def create
        permitted = event_params
        result = Events::Ingest.call(
          source: api_credential.source,
          external_id: permitted.delete(:external_id),
          payload: permitted
        )

        render_result(result)
      end

      private

      def event_params
        params.permit(
          :external_id, :title, :description, :venue, :category, :url,
          :image_url, :starts_at, :ends_at, :price, :score, :confidence,
          :why, :ticket_urgency, :age_limit
        ).to_h.symbolize_keys
      end

      def render_result(result)
        if result.success?
          render json: {
            status: result.status,
            event: { id: result.event.id, source: result.event.source, external_id: result.event.external_id }
          }, status: result.status == :created ? :created : :ok
        else
          render json: { status: result.status, errors: result.errors }, status: :unprocessable_content
        end
      end
    end
  end
end
