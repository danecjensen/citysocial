module Feedback
  module Admin
    class SubmissionsController < PlatformCore::BaseController
      before_action :require_admin
      before_action :set_submission, only: :update

      def index
        @status = Submission::STATUSES.include?(params[:status]) ? params[:status] : nil
        @submissions = Submission.all
        @submissions = @submissions.where(status: @status) if @status
        @submissions = @submissions.recent
      end

      def update
        if @submission.update(status_params)
          redirect_to admin_submissions_path, notice: "Feedback status updated."
        else
          redirect_to admin_submissions_path, alert: @submission.errors.full_messages.to_sentence
        end
      end

      private

      def set_submission
        @submission = Submission.find(params[:id])
      end

      def status_params
        params.require(:submission).permit(:status)
      end
    end
  end
end
