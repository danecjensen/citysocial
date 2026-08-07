module PickupSports
  class GamesController < PlatformCore::BaseController
    before_action :require_login, except: %i[index show]
    before_action :set_game, only: %i[show edit update cancel]
    before_action :require_owner, only: %i[edit update cancel]

    def index
      @sport = params[:sport].presence_in(Game::SPORTS)
      @neighborhood = params[:neighborhood].to_s.strip.presence
      @date = parsed_date

      @games = Game.upcoming.includes(:roster_entries)
      @games = @games.by_sport(@sport) if @sport
      @games = @games.in_neighborhood(@neighborhood) if @neighborhood
      @games = @games.on_date(@date) if @date
      @hosts = PlatformCore::Graph.users(@games.map(&:host_id))
    end

    def show
      @entries = @game.roster_entries.order(Arel.sql("CASE status WHEN 'joined' THEN 0 ELSE 1 END"), :created_at, :id)
      @residents = PlatformCore::Graph.users(@entries.map(&:resident_id))
      @current_entry = @game.entry_for(current_user.id) if logged_in?
    end

    def new
      @game = Game.new(starts_at: 2.days.from_now.change(min: 0), capacity: 12)
    end

    def edit; end

    def create
      @game = Game.new(game_params.merge(host_id: current_user.id))
      if @game.save
        redirect_to game_path(@game), notice: "Game posted. You're on the roster."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @game.update(game_params)
        redirect_to game_path(@game), notice: "Game details updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def cancel
      @game.cancel!
      redirect_to game_path(@game), notice: "Game canceled. The roster is preserved for clarity."
    end

    private

    def set_game
      @game = Game.find(params[:id])
    end

    def require_owner
      return if @game.host_id == current_user.id

      redirect_to game_path(@game), alert: "Only the host can change this game."
    end

    def game_params
      params.require(:game).permit(
        :title, :sport, :skill_level, :neighborhood, :venue, :details, :starts_at, :capacity
      )
    end

    def parsed_date
      Date.iso8601(params[:on]) if params[:on].present?
    rescue Date::Error
      nil
    end
  end
end
