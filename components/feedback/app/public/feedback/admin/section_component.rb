module Feedback
  module Admin
    # PUBLIC: the module's triage section of the single-page admin dashboard
    # (/admin). Registered with PlatformCore::AdminSections from the engine so
    # the kernel renders it without referencing a Feedback constant.
    #
    # The status filter lives in the shared page URL as `feedback_status`, which
    # keeps it from colliding with any other section's params.
    class SectionComponent < ViewComponent::Base
      LIMIT = 25

      def initialize(params: {})
        requested = params[:feedback_status].to_s
        @status = Feedback::Submission::STATUSES.include?(requested) ? requested : nil
      end

      attr_reader :status

      def submissions
        @submissions ||= matching.recent.limit(LIMIT).to_a
      end

      def total_count
        @total_count ||= matching.count
      end

      def truncated?
        total_count > submissions.size
      end

      def status_options
        Feedback::Submission::STATUSES.map { |value| [Feedback::Submission::STATUS_LABELS.fetch(value), value] }
      end

      def filter_path(value = nil)
        value.present? ? "/admin?feedback_status=#{value}#section-feedback" : "/admin#section-feedback"
      end

      def submission_path(submission)
        helpers.feedback.submission_path(submission)
      end

      def update_path(submission)
        helpers.feedback.admin_submission_path(submission)
      end

      private

      def matching
        @matching ||= status ? Feedback::Submission.where(status: status) : Feedback::Submission.all
      end
    end
  end
end
