module Restaurants
  class LeaderboardController < PlatformCore::BaseController
    before_action :require_login

    def index
      @restaurants = Restaurants::Restaurant.ranked
    end
  end
end
