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

  describe "recent picks feed on the leaderboard" do
    def select_restaurant_queries(&block)
      count = 0
      counter = lambda do |*args|
        payload = args.last
        count += 1 if payload[:sql] =~ /SELECT.+restaurants_restaurants/i
      end
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
      count
    end

    it "lists the latest decisions as 'winner beat loser', newest first" do
      franklin = create(:restaurant, name: "Franklin Barbecue")
      uchi = create(:restaurant, name: "Uchi")
      Restaurants::Vote.create!(voter_id: 1, winner_id: uchi.id, loser_id: franklin.id, created_at: 1.hour.ago)
      Restaurants::Vote.create!(voter_id: 1, winner_id: franklin.id, loser_id: uchi.id)
      login_as(create(:user))

      get "/restaurants/leaderboard"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Recent picks")
      expect(response.body).to include("beat")
      # Newest pick (Franklin beat Uchi) is rendered above the older one.
      body = response.body
      feed = body[body.index("Recent picks")..]
      expect(feed.index("Franklin Barbecue")).to be < feed.index("Uchi")
    end

    it "skips a pick whose winner or loser no longer exists without erroring" do
      franklin = create(:restaurant, name: "Franklin Barbecue")
      uchi = create(:restaurant, name: "Uchi")
      Restaurants::Vote.create!(voter_id: 1, winner_id: franklin.id, loser_id: uchi.id)
      uchi.destroy
      login_as(create(:user))

      get "/restaurants/leaderboard"

      expect(response).to have_http_status(:ok)
      # The orphaned decision is dropped from the feed, leaving no picks to show.
      expect(response.body).to include("No picks yet")
    end

    it "shows an empty feed state when restaurants exist but nobody has voted" do
      create(:restaurant, name: "Franklin Barbecue")
      login_as(create(:user))

      get "/restaurants/leaderboard"

      expect(response.body).to include("Recent picks")
      expect(response.body).to include("No picks yet")
    end

    it "resolves recent-pick restaurants in a flat number of queries as votes grow" do
      franklin = create(:restaurant, name: "Franklin Barbecue")
      uchi = create(:restaurant, name: "Uchi")
      login_as(create(:user))

      Restaurants::Vote.create!(voter_id: 1, winner_id: franklin.id, loser_id: uchi.id)
      few = select_restaurant_queries { get "/restaurants/leaderboard" }

      6.times { Restaurants::Vote.create!(voter_id: 1, winner_id: franklin.id, loser_id: uchi.id) }
      many = select_restaurant_queries { get "/restaurants/leaderboard" }

      expect(many).to eq(few)
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
