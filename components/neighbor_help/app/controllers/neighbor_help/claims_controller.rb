module NeighborHelp
  class ClaimsController < PlatformCore::BaseController
    before_action :require_login
    before_action :set_request

    def create
      @request.claim!(current_user.id)
      redirect_to request_path(@request), notice: "You claimed this favor. Release it promptly if plans change."
    rescue Request::TransitionError => e
      redirect_to request_path(@request), alert: e.message
    end

    def destroy
      @request.release!(current_user.id)
      redirect_to request_path(@request), notice: "Favor released so another neighbor can help."
    rescue Request::TransitionError => e
      redirect_to request_path(@request), alert: e.message
    end

    private

    def set_request
      @request = Request.find(params[:request_id])
    end
  end
end
