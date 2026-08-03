module Communities
  class CommunitiesController < PlatformCore::BaseController
    before_action :require_login, only: %i[new create join leave]
    before_action :set_community, only: %i[show join leave]

    def index
      @communities = Communities::Community.popular
    end

    def show
      @posts = @community.posts.hot
    end

    def new
      @community = Communities::Community.new
    end

    def create
      @community = Communities::Community.new(community_params)
      @community.creator_id = current_user.id
      if @community.save
        redirect_to community_path(@community), notice: "Created c/#{@community.name}."
      else
        render :new, status: :unprocessable_content
      end
    end

    def join
      @community.join!(current_user.id)
      redirect_to community_path(@community), notice: "Joined c/#{@community.name}."
    end

    def leave
      if @community.leave!(current_user.id)
        redirect_to community_path(@community), notice: "Left c/#{@community.name}."
      else
        redirect_to community_path(@community), alert: "Owners can't leave their own community."
      end
    end

    private

    def set_community
      @community = Communities::Community.find_by!(slug: params[:slug])
    end

    def community_params
      params.require(:community).permit(:name, :description, :category)
    end
  end
end
