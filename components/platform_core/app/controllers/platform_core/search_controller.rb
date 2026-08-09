module PlatformCore
  class SearchController < BaseController
    def show
      @response = PlatformCore::Search.call(query: params[:q], type: params[:type])
      @type_options = [["All public results", ""]] + PlatformCore::Search.type_options
    end
  end
end
