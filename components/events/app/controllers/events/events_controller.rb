module Events
  # Read-only public browsing surface. Events enter the store through
  # Events::Ingest (a rake feed), never through this controller — so there is no
  # login requirement and no write actions here.
  class EventsController < PlatformCore::BaseController
    PER_PAGE = 24

    # The home page: the 10 best-scoring events in the next 7 days, refreshed
    # every time the feed is ingested. Selection is deterministic SQL.
    def index
      @events = Events::Event.weekly_top(10)
      @window_end = 7.days.from_now.in_time_zone(Events::Event::TIME_ZONE).to_date
    end

    # The searchable archive: every event, filterable by keyword and category.
    def all
      @q = params[:q].to_s.strip
      @category = params[:category].presence
      @page = [params[:page].to_i, 1].max

      scope = Events::Event.all
      scope = scope.search(@q) if @q.present?
      scope = scope.by_category(@category) if @category
      scope = scope.chronological

      @total = scope.count
      @events = scope.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
      @has_next = @page * PER_PAGE < @total
    end

    def show
      @event = Events::Event.find(params[:id])
    end
  end
end
