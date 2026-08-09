module PickupSports
  class GameSeriesController < PlatformCore::BaseController
    before_action :require_login, except: :show

    def show
      @game_series = GameSeries.find(params[:id])
      @games = @game_series.games.includes(:roster_entries)
      @host = PlatformCore::Graph.user(@game_series.host_id)
    end

    def new
      @game_series = GameSeries.new(
        starts_at: 2.days.from_now.change(min: 0),
        capacity: 12,
        occurrences_count: 4
      )
    end

    def create
      @game_series = GameSeries.new(game_series_params.merge(host_id: current_user.id))
      if @game_series.schedule
        redirect_to series_path(@game_series), notice: "Weekly series posted. You're on every roster."
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def game_series_params
      params.require(:game_series).permit(
        :title, :sport, :skill_level, :neighborhood, :venue, :details, :starts_at, :capacity, :occurrences_count
      )
    end
  end
end
