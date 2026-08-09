module NeighborHelp
  module Admin
    class RequestsController < PlatformCore::BaseController
      before_action :require_admin
      before_action :set_request, only: :update

      def index
        @reports = Report.pending.includes(:request).recent
        @residents = PlatformCore::Graph.users(@reports.flat_map do |report|
          [report.reporter_id, report.request.requester_id]
        end)
      end

      def update
        state = params.require(:request).fetch(:moderation_state).presence_in(%w[visible hidden])
        raise ActionController::BadRequest, "unsupported moderation state" unless state

        @request.moderate!(moderator_id: current_user.id, state: state)
        report_status = state == "hidden" ? "reviewed" : "dismissed"
        @request.reports.pending.update_all(status: report_status, updated_at: Time.current)
        redirect_to admin_requests_path, notice: state == "hidden" ? "Favor hidden." : "Favor restored."
      end

      private

      def set_request
        @request = Request.find(params[:id])
      end
    end
  end
end
