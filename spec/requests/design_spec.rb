require "rails_helper"

RSpec.describe "Design style guide", type: :request do
  it "renders every component in the catalog" do
    get "/design"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Design system")
    # smoke: one marker per component family
    expect(response.body).to include("Franklin Barbecue") # table
    expect(response.body).to include("Nothing here yet")  # empty state
    expect(response.body).to include("Welcome back to CitySocial.") # flash
  end
end
