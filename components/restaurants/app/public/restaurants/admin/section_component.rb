module Restaurants
  module Admin
    # PUBLIC: the module's section of the single-page admin dashboard (/admin).
    # It is registered with PlatformCore::AdminSections from the engine, so the
    # kernel can render it without ever referencing a Restaurants constant.
    #
    # The catalog runs to hundreds of rows, so the list is search-filtered and
    # capped; the search term rides along in the page URL (`restaurant_q`) and in
    # every form, so editing a row returns the admin to the same filtered view.
    class SectionComponent < ViewComponent::Base
      LIMIT = 25

      BASE_PATH = "/restaurants/admin/restaurants".freeze

      def initialize(params: {})
        @query = params[:restaurant_q].to_s.strip
      end

      attr_reader :query

      def restaurants
        @restaurants ||= matching.limit(LIMIT).to_a
      end

      def total_count
        @total_count ||= matching.count
      end

      def truncated?
        total_count > restaurants.size
      end

      def new_restaurant
        @new_restaurant ||= Restaurants::Restaurant.new
      end

      def restaurant_path(restaurant)
        "#{BASE_PATH}/#{restaurant.id}"
      end

      def photo_path(restaurant, photo)
        "#{BASE_PATH}/#{restaurant.id}/photos/#{photo.id}"
      end

      def photo_url(photo)
        helpers.main_app.rails_blob_path(photo, only_path: true)
      end

      private

      def matching
        @matching ||= begin
          scope = Restaurants::Restaurant.ranked.with_attached_photos
          if query.present?
            term = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
            scope = scope.where("name ILIKE :term OR cuisine ILIKE :term OR area ILIKE :term", term: term)
          end
          scope
        end
      end
    end
  end
end
