module PickupSports
  class RosterEntriesController < PlatformCore::BaseController
    before_action :require_login
    before_action :set_game

    def create
      entry = @game.join!(current_user.id)
      message = entry.waitlisted? ? "Game full — you're in line based on join time." : "You're on the roster."
      redirect_to game_path(@game), notice: message
    rescue Game::ParticipationError => e
      redirect_to game_path(@game), alert: e.message
    end

    def destroy
      promoted = @game.leave!(current_user.id)
      message = promoted ? "You left the game. The next waitlisted resident was promoted." : "You left the game."
      redirect_to game_path(@game), notice: message
    rescue Game::ParticipationError => e
      redirect_to game_path(@game), alert: e.message
    end

    private

    def set_game
      @game = Game.find(params[:game_id])
    end
  end
end
