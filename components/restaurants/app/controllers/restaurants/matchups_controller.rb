module Restaurants
  class MatchupsController < PlatformCore::BaseController
    before_action :require_login

    def new
      @pair = Restaurants::Restaurant.random_pair
    end

    def create
      winner_id = integer_id_param(:winner_id)
      loser_id = integer_id_param(:loser_id)

      if winner_id == loser_id
        redirect_to "/restaurants", alert: "A restaurant can't beat itself."
      else
        result = Restaurants::RecordMatchup.call(
          winner_id: winner_id,
          loser_id: loser_id,
          voter_id: current_user.id
        )
        redirect_to "/restaurants", notice: "Nice pick — #{result.winner_name} moves up."
      end
    end

    private

    def integer_id_param(name)
      Integer(params[name], exception: false) || raise(ActiveRecord::RecordNotFound)
    end
  end
end
