module Restaurants
  module Admin
    # Actions behind the "Restaurants" section of the single-page admin
    # dashboard (/admin). Every action redirects back to that section, keeping
    # the admin's current search so the row they just edited is still on screen.
    class RestaurantsController < PlatformCore::BaseController
      before_action :require_login
      before_action :require_admin
      before_action :set_restaurant, only: %i[update destroy destroy_photo]

      # Legacy standalone page: the admin area is one page now.
      def index
        redirect_to dashboard_section
      end

      def create
        restaurant = Restaurants::Restaurant.new(restaurant_attributes)
        photos = submitted_photos

        if restaurant.save
          restaurant.photos.attach(photos) if photos.any?
          redirect_to dashboard_section, notice: "Added #{restaurant.name}."
        else
          redirect_to dashboard_section, alert: "Could not add restaurant: #{errors_for(restaurant)}"
        end
      end

      # Edits the details, APPENDS any newly uploaded photos (assigning `photos=`
      # would replace the existing set), and optionally pins a new hero.
      def update
        photos = submitted_photos

        if @restaurant.update(restaurant_attributes)
          @restaurant.photos.attach(photos) if photos.any?
          pin_hero_photo
          redirect_to dashboard_section, notice: "Updated #{@restaurant.name}."
        else
          redirect_to dashboard_section, alert: "Could not update #{@restaurant.name}: #{errors_for(@restaurant)}"
        end
      end

      def destroy
        @restaurant.destroy
        redirect_to dashboard_section, notice: "Removed #{@restaurant.name}."
      end

      def destroy_photo
        photo = @restaurant.photos.attachments.find_by(id: params[:photo_id])
        return redirect_to(dashboard_section, alert: "That photo is no longer attached.") if photo.nil?

        @restaurant.update(hero_photo_id: nil) if @restaurant.hero_photo_id == photo.id
        photo.purge
        redirect_to dashboard_section, notice: "Removed a photo from #{@restaurant.name}."
      end

      private

      def set_restaurant
        @restaurant = Restaurants::Restaurant.find(params[:id])
      end

      def restaurant_params
        params.fetch(:restaurant, {}).permit(:name, :cuisine, :area, :hero_photo_id, photos: [])
      end

      def restaurant_attributes
        restaurant_params.slice(:name, :cuisine, :area)
      end

      # `file_field multiple: true` always posts a blank placeholder value, which
      # ActiveStorage refuses to attach -- drop it.
      def submitted_photos
        Array(restaurant_params[:photos]).compact_blank
      end

      # Only a photo actually attached to THIS restaurant may become its hero.
      def pin_hero_photo
        id = restaurant_params[:hero_photo_id].presence
        return if id.nil?

        photo = @restaurant.photos.attachments.find_by(id: id)
        @restaurant.update(hero_photo_id: photo.id) if photo
      end

      def errors_for(restaurant)
        restaurant.errors.full_messages.to_sentence.presence || "unknown error"
      end

      def dashboard_section
        query = { restaurant_q: params[:restaurant_q].presence }.compact
        suffix = query.any? ? "?#{query.to_query}" : ""
        "/admin#{suffix}#section-restaurants"
      end
    end
  end
end
