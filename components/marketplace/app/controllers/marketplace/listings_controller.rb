module Marketplace
  class ListingsController < PlatformCore::BaseController
    before_action :require_login, except: %i[index show]
    before_action :set_listing, only: %i[show edit update destroy mark_sold]
    before_action :require_owner, only: %i[edit update destroy mark_sold]

    def index
      @category = params[:category].presence
      @listings = Marketplace::Listing.active_listings
      @listings = @listings.search(params[:q]) if params[:q].present?
      @listings = @listings.by_category(@category) if @category
      @listings = sorted(@listings)
    end

    def show
      @listing.increment_views! unless owner?(@listing)
    end

    def new
      @listing = Marketplace::Listing.new
    end

    def edit; end

    def create
      @listing = Marketplace::Listing.new(listing_params)
      @listing.author_id = current_user.id
      if @listing.save
        redirect_to listing_path(@listing), notice: "Listing posted."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @listing.update(listing_params)
        redirect_to listing_path(@listing), notice: "Listing updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @listing.destroy
      redirect_to mine_listings_path, notice: "Listing removed."
    end

    def mark_sold
      @listing.mark_sold!
      redirect_to listing_path(@listing), notice: "Marked as sold."
    end

    def mine
      @listings = Marketplace::Listing.where(author_id: current_user.id).recent
    end

    private

    def set_listing
      @listing = Marketplace::Listing.find_by!(slug: params[:slug])
    end

    def owner?(listing)
      logged_in? && listing.author_id == current_user.id
    end

    def require_owner
      redirect_to listing_path(@listing), alert: "That isn't your listing." unless owner?(@listing)
    end

    def sorted(scope)
      case params[:sort]
      when "price_asc" then scope.by_price_asc
      when "price_desc" then scope.by_price_desc
      else scope.recent
      end
    end

    def listing_params
      params.require(:listing).permit(:title, :description, :category, :condition, :price, :location, photos: [])
    end
  end
end
