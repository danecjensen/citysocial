module Restaurants
  class LeaderboardController < PlatformCore::BaseController
    before_action :require_login

    def index
      @cuisines = Restaurants::Restaurant.cuisines
      # Only honor a cuisine that actually exists in the catalog, so an unknown
      # value falls back to the full board rather than an empty one.
      @cuisine = params[:cuisine].presence_in(@cuisines)
      @restaurants = Restaurants::Restaurant.ranked.by_cuisine(@cuisine).with_attached_photos
    end
  end
end
