module Restaurants
  class MatchupsController < PlatformCore::BaseController
    before_action :require_login

    def new
      @pair = Restaurants::Restaurant.random_pair
    end

    def create
      winner = Restaurants::Restaurant.find(params[:winner_id])
      loser = Restaurants::Restaurant.find(params[:loser_id])

      if winner == loser
        redirect_to "/restaurants", alert: "A restaurant can't beat itself."
      else
        Restaurants::RecordMatchup.call(winner: winner, loser: loser, voter_id: current_user.id)
        redirect_to "/restaurants", notice: "Nice pick — #{winner.name} moves up."
      end
    end
  end
end
