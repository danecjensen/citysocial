module Restaurants
  module Admin
    class RestaurantsController < PlatformCore::BaseController
      before_action :require_login
      before_action :require_admin

      def index
        @restaurants = Restaurants::Restaurant.ranked
        @restaurant = Restaurants::Restaurant.new
      end

      def create
        @restaurant = Restaurants::Restaurant.new(restaurant_params)
        if @restaurant.save
          redirect_to "/restaurants/admin/restaurants", notice: "Added #{@restaurant.name}."
        else
          @restaurants = Restaurants::Restaurant.ranked
          render :index, status: :unprocessable_content
        end
      end

      def destroy
        restaurant = Restaurants::Restaurant.find(params[:id])
        restaurant.destroy
        redirect_to "/restaurants/admin/restaurants", notice: "Removed #{restaurant.name}."
      end

      private

      def restaurant_params
        params.require(:restaurant).permit(:name, :cuisine, :area)
      end
    end
  end
end
