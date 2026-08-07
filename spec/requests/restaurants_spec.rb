require "rails_helper"

RSpec.describe "Restaurants", type: :request do
  def login_as(user, password: "s3cret-password")
    post "/login", params: { email: user.email, password: password }
  end

  describe "matchups" do
    it "redirects anonymous users to login" do
      get "/restaurants"
      expect(response).to redirect_to("/login")
    end

    it "shows a matchup to a logged-in user" do
      create(:restaurant, name: "Franklin Barbecue")
      create(:restaurant, name: "Uchi")
      login_as(create(:user))

      get "/restaurants"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Which is better?")
    end

    it "records a vote and updates Elo" do
      winner = create(:restaurant)
      loser = create(:restaurant)
      login_as(create(:user))

      expect do
        post "/restaurants/matchups", params: { winner_id: winner.id, loser_id: loser.id }
      end.to change(Restaurants::Vote, :count).by(1)

      expect(winner.reload.elo).to be > loser.reload.elo
      expect(response).to redirect_to("/restaurants")
    end
  end

  describe "leaderboard" do
    it "lists restaurants ranked by Elo" do
      create(:restaurant, name: "Low", elo: 1400)
      create(:restaurant, name: "High", elo: 1600)
      login_as(create(:user))

      get "/restaurants/leaderboard"
      expect(response).to have_http_status(:ok)
      expect(response.body.index("High")).to be < response.body.index("Low")
    end

    it "renders an empty state instead of a bare table when there are no restaurants" do
      login_as(create(:user))

      get "/restaurants/leaderboard"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No restaurants on the board yet")
    end

    it "renders a cuisine filter select populated from the cuisines present" do
      create(:restaurant, name: "Franklin Barbecue", cuisine: "BBQ")
      create(:restaurant, name: "Veracruz", cuisine: "Tacos")
      login_as(create(:user))

      get "/restaurants/leaderboard"

      doc = Capybara.string(response.body)
      expect(doc).to have_css("select[name='cuisine'] option", text: "BBQ")
      expect(doc).to have_css("select[name='cuisine'] option", text: "Tacos")
    end

    it "narrows the leaderboard to the selected cuisine" do
      create(:restaurant, name: "Franklin Barbecue", cuisine: "BBQ")
      create(:restaurant, name: "Veracruz Taqueria", cuisine: "Tacos")
      login_as(create(:user))

      get "/restaurants/leaderboard", params: { cuisine: "BBQ" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Franklin Barbecue")
      expect(response.body).not_to include("Veracruz Taqueria")
    end

    it "shows the complete leaderboard when no cuisine is selected" do
      create(:restaurant, name: "Franklin Barbecue", cuisine: "BBQ")
      create(:restaurant, name: "Veracruz Taqueria", cuisine: "Tacos")
      login_as(create(:user))

      get "/restaurants/leaderboard"

      expect(response.body).to include("Franklin Barbecue")
      expect(response.body).to include("Veracruz Taqueria")
    end

    it "ignores an unknown cuisine and shows the full board" do
      create(:restaurant, name: "Franklin Barbecue", cuisine: "BBQ")
      create(:restaurant, name: "Veracruz Taqueria", cuisine: "Tacos")
      login_as(create(:user))

      get "/restaurants/leaderboard", params: { cuisine: "Nonexistent" }

      expect(response.body).to include("Franklin Barbecue")
      expect(response.body).to include("Veracruz Taqueria")
    end
  end

  describe "admin restaurant management" do
    it "blocks non-admins" do
      login_as(create(:user))
      get "/restaurants/admin/restaurants"
      expect(response).to redirect_to("/")
    end

    it "lets an admin add a restaurant" do
      login_as(create(:user, :admin))

      expect do
        post "/restaurants/admin/restaurants",
             params: { restaurant: { name: "Suerte", cuisine: "Mexican", area: "East Austin" } }
      end.to change(Restaurants::Restaurant, :count).by(1)
    end
  end
end
