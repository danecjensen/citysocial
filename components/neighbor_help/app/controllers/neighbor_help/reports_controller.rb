module NeighborHelp
  class ReportsController < PlatformCore::BaseController
    before_action :require_login
    before_action :set_request

    def create
      report = @request.reports.new(report_params.merge(reporter_id: current_user.id))
      if report.save
        redirect_to request_path(@request), notice: "Report received. An admin will review the favor."
      else
        redirect_to request_path(@request), alert: report.errors.full_messages.to_sentence
      end
    end

    private

    def set_request
      @request = Request.find(params[:request_id])
    end

    def report_params
      params.require(:report).permit(:reason, :details)
    end
  end
end
