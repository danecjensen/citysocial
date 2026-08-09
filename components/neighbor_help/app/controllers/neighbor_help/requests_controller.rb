module NeighborHelp
  class RequestsController < PlatformCore::BaseController
    before_action :require_login, except: %i[index show]
    before_action :set_request, only: %i[show complete cancel]
    before_action :ensure_request_visible, only: :show

    def index
      @category = params[:category].presence_in(Request::CATEGORIES)
      @neighborhood = params[:neighborhood].to_s.strip.presence
      @date = parsed_date

      @requests = Request.publicly_visible.current.order(:starts_at, :id)
      @requests = @requests.by_category(@category) if @category
      @requests = @requests.in_neighborhood(@neighborhood) if @neighborhood
      @requests = @requests.on_date(@date) if @date
      @residents = PlatformCore::Graph.users(@requests.flat_map { |request| [request.requester_id, request.helper_id] })
    end

    def show
      @residents = PlatformCore::Graph.users([@request.requester_id, @request.helper_id])
      @report = Report.new
    end

    def new
      @request = Request.new(
        starts_at: 1.day.from_now.change(min: 0),
        ends_at: 1.day.from_now.change(min: 0) + 2.hours,
        estimated_minutes: 45
      )
    end

    def create
      @request = Request.new(request_params.merge(requester_id: current_user.id))
      if @request.save
        redirect_to request_path(@request), notice: "Favor posted. Neighbors can now claim it."
      else
        render :new, status: :unprocessable_content
      end
    end

    def complete
      @request.complete!(current_user.id)
      redirect_to request_path(@request), notice: "Favor marked complete."
    rescue Request::TransitionError => e
      redirect_to request_path(@request), alert: e.message
    end

    def cancel
      @request.cancel!(current_user.id)
      redirect_to request_path(@request), notice: "Favor canceled."
    rescue Request::TransitionError => e
      redirect_to request_path(@request), alert: e.message
    end

    private

    def set_request
      @request = Request.find(params[:id])
    end

    def ensure_request_visible
      return unless @request.hidden?
      return if admin?
      return if logged_in? && current_user.id.in?([@request.requester_id, @request.helper_id])

      raise ActiveRecord::RecordNotFound
    end

    def request_params
      params.require(:request).permit(
        :title, :details, :category, :neighborhood, :starts_at, :ends_at,
        :estimated_minutes, :logistics_notes, :no_cash_confirmed
      )
    end

    def parsed_date
      Date.iso8601(params[:on]) if params[:on].present?
    rescue Date::Error
      nil
    end
  end
end
