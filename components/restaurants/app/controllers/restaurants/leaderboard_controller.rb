module Restaurants
  class LeaderboardController < PlatformCore::BaseController
    before_action :require_login

    def index
      @restaurants = Restaurants::Restaurant.ranked.with_attached_photos
    end
  end
end
