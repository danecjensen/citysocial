require "rails_helper"

RSpec.describe "About page", type: :request do
  it "introduces Dane and the CitySocial vision" do
    get "/about"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Hi, I’m Dane Jensen.")
    expect(response.body).to include("intentionally fewer than 200 people")
    expect(response.body).to include("Local news that matters")
    expect(response.body).to include("I’m at this café—come meet me.")
    expect(response.body).to include("How borrowing a tool could work")
  end

  it "links to the page from the top navigation" do
    get "/about"

    expect(response.body).to include(%(href="/about"))
    expect(response.body).to include(">About</a>")
  end
end
