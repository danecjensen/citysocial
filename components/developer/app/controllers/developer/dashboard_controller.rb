module Developer
  class DashboardController < BaseController
    def index
      @model_stats = developer_models.map { |model| [model, model.count] }
    end
  end
end
