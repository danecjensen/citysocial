module Feedback
  module Admin
    # Actions behind the "Feedback" section of the single-page admin dashboard
    # (/admin). Triage happens inline on that page; this controller only applies
    # the change and sends the admin back to the section they were working in.
    class SubmissionsController < PlatformCore::BaseController
      before_action :require_admin
      before_action :set_submission, only: :update

      # Legacy standalone page: the admin area is one page now.
      def index
        redirect_to dashboard_section
      end

      def update
        if @submission.update(status_params)
          redirect_to dashboard_section, notice: "Feedback status updated."
        else
          redirect_to dashboard_section, alert: @submission.errors.full_messages.to_sentence
        end
      end

      private

      def set_submission
        @submission = Submission.find(params[:id])
      end

      def status_params
        params.require(:submission).permit(:status)
      end

      def dashboard_section
        filter = params[:feedback_status].presence
        suffix = filter ? "?#{{ feedback_status: filter }.to_query}" : ""
        "/admin#{suffix}#section-feedback"
      end
    end
  end
end
