module Feedback
  class SubmissionsController < PlatformCore::BaseController
    before_action :require_login, only: %i[new create toggle_support]
    before_action :set_submission, only: %i[show toggle_support]

    def index
      @kind = Submission::KINDS.include?(params[:kind]) ? params[:kind] : nil
      @status = Submission::STATUSES.include?(params[:status]) ? params[:status] : nil
      @area = area_keys.include?(params[:area]) ? params[:area] : nil
      @sort = params[:sort] == "newest" ? "newest" : "top"
      @query = params[:q].to_s.strip.presence

      scope = Submission.all
      scope = scope.where(kind: @kind) if @kind
      scope = scope.where(status: @status) if @status
      scope = scope.where(area: @area) if @area
      scope = search(scope) if @query
      @submissions = @sort == "newest" ? scope.recent : scope.most_supported
      @supported_submission_ids = supported_submission_ids(@submissions)
    end

    def show
      @supported = @submission.supported_by?(current_user&.id)
    end

    def new
      @submission = Submission.new(prefill_params)
    end

    def create
      @submission = Submission.new(submission_params)
      @submission.author_id = current_user.id

      if @submission.save
        redirect_to submission_path(@submission), notice: "Thanks — your feedback is now on the board."
      else
        render :new, status: :unprocessable_content
      end
    end

    def toggle_support
      support = @submission.supports.find_by(user_id: current_user.id)

      if support
        support.destroy!
        message = "Support removed."
      else
        @submission.supports.create!(user_id: current_user.id)
        message = "You are supporting this feedback."
      end

      redirect_back_or_to submission_path(@submission), notice: message
    rescue ActiveRecord::RecordNotUnique
      redirect_back_or_to submission_path(@submission), notice: "You are already supporting this feedback."
    end

    private

    def set_submission
      @submission = Submission.find(params[:id])
    end

    def submission_params
      params.require(:submission).permit(:kind, :area, :page_url, :title, :description)
    end

    def prefill_params
      prefill = params.permit(:kind, :area, :page_url).slice(:kind, :area, :page_url)
      prefill[:area] ||= inferred_area(prefill[:page_url])
      prefill
    end

    def supported_submission_ids(scope)
      return [] unless logged_in?

      Support.where(user_id: current_user.id, submission_id: scope.select(:id)).pluck(:submission_id)
    end

    def search(scope)
      pattern = "%#{Submission.sanitize_sql_like(@query.downcase)}%"
      scope.where(
        "LOWER(title) LIKE :query OR LOWER(description) LIKE :query OR LOWER(COALESCE(area, '')) LIKE :query",
        query: pattern
      )
    end

    def area_keys
      PlatformCore::Modules.all.map(&:key)
    end

    def inferred_area(page_url)
      return if page_url.blank?

      area_keys.find do |key|
        page_url == "/#{key}" || page_url.start_with?("/#{key}/", "/#{key}?")
      end
    end
  end
end
