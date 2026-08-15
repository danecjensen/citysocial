module SharedCalendar
  class EventsController < PlatformCore::BaseController
    before_action :require_login, except: %i[index show]
    before_action :set_event, only: %i[show edit update destroy]
    before_action :require_owner, only: %i[edit update destroy]

    def index
      @month = requested_month
      @category = params[:category].presence_in(Event::CATEGORIES.keys)
      @calendar_days = calendar_days_for(@month)

      scope = Event.with_attached_image.during(month_range(@month)).chronological
      scope = scope.where(category: @category) if @category
      @events = scope.to_a
      @events_by_date = @events.group_by { |event| event.starts_at.in_time_zone.to_date }
      @featured_events = @events.select { |event| event.image.attached? }.first(3)
    end

    def show
      @author = PlatformCore::Graph.user(@event.author_id)
    end

    def new
      @event = Event.new(
        starts_at: suggested_start_time,
        ends_at: suggested_start_time + 2.hours
      )
    end

    def edit; end

    def create
      @event = Event.new(event_params)
      @event.author_id = current_user.id

      if @event.save
        redirect_to event_path(@event), notice: "Event added to the community calendar."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @event.update(event_params)
        redirect_to event_path(@event), notice: "Event updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      month = @event.starts_at.in_time_zone.to_date.beginning_of_month
      @event.destroy!
      redirect_to events_path(month: month.strftime("%Y-%m")), notice: "Event removed from the calendar."
    end

    private

    def set_event
      @event = Event.with_attached_image.find(params[:id])
    end

    def require_owner
      return if @event.author_id == current_user.id

      redirect_to event_path(@event), alert: "Only the resident who added this event can change it."
    end

    def event_params
      params.require(:event).permit(
        :title,
        :description,
        :category,
        :starts_at,
        :ends_at,
        :venue_name,
        :location,
        :image
      )
    end

    def requested_month
      return Time.zone.today.beginning_of_month if params[:month].blank?

      Date.strptime(params[:month], "%Y-%m").beginning_of_month
    rescue Date::Error
      Time.zone.today.beginning_of_month
    end

    def month_range(month)
      month.beginning_of_month.beginning_of_day..month.end_of_month.end_of_day
    end

    def calendar_days_for(month)
      first = month.beginning_of_month.beginning_of_week(:sunday)
      last = month.end_of_month.end_of_week(:sunday)
      (first..last).to_a
    end

    def suggested_start_time
      requested = params[:date].presence && Date.iso8601(params[:date])
      date = requested || Time.zone.tomorrow
      Time.zone.local(date.year, date.month, date.day, 18)
    rescue Date::Error
      Time.zone.tomorrow.change(hour: 18)
    end
  end
end
