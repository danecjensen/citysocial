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
    def photo_upload(filename: "hero.png")
      Rack::Test::UploadedFile.new(StringIO.new(TestImages.png_1x1), "image/png", original_filename: filename)
    end

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

      expect(response).to redirect_to("/admin#section-restaurants")
    end

    it "adds a restaurant with photos and ignores the blank file placeholder" do
      login_as(create(:user, :admin))

      post "/restaurants/admin/restaurants",
           params: { restaurant: { name: "Nixta Taqueria", photos: ["", photo_upload] } }

      restaurant = Restaurants::Restaurant.find_by(name: "Nixta Taqueria")
      expect(restaurant.photos.attachments.size).to eq(1)
    end

    it "reports validation errors instead of silently dropping the restaurant" do
      login_as(create(:user, :admin))

      expect do
        post "/restaurants/admin/restaurants", params: { restaurant: { name: "" } }
      end.not_to change(Restaurants::Restaurant, :count)

      expect(flash[:alert]).to include("Name can't be blank")
    end

    it "edits details and appends photos rather than replacing them" do
      restaurant = create(:restaurant, :with_photo, name: "Uchi", cuisine: "Sushi")
      login_as(create(:user, :admin))

      patch "/restaurants/admin/restaurants/#{restaurant.id}",
            params: { restaurant: { name: "Uchi", cuisine: "Japanese", area: "South Lamar", photos: [photo_upload] } }

      restaurant.reload
      expect(restaurant.cuisine).to eq("Japanese")
      expect(restaurant.photos.attachments.size).to eq(2)
    end

    it "pins a hero photo and keeps the search term on the way back" do
      restaurant = create(:restaurant, :with_photo, name: "Loro")
      restaurant.photos.attach(io: StringIO.new(TestImages.png_1x1), filename: "second.png", content_type: "image/png")
      second = restaurant.photos.attachments.max_by(&:id)
      login_as(create(:user, :admin))

      patch "/restaurants/admin/restaurants/#{restaurant.id}",
            params: { restaurant: { hero_photo_id: second.id }, restaurant_q: "loro" }

      expect(restaurant.reload.hero_photo.id).to eq(second.id)
      expect(response).to redirect_to("/admin?restaurant_q=loro#section-restaurants")
    end

    it "refuses to pin a photo attached to another restaurant" do
      restaurant = create(:restaurant, :with_photo)
      other = create(:restaurant, :with_photo)
      login_as(create(:user, :admin))

      patch "/restaurants/admin/restaurants/#{restaurant.id}",
            params: { restaurant: { hero_photo_id: other.photos.attachments.first.id } }

      expect(restaurant.reload.hero_photo_id).to be_nil
    end

    it "removes a photo and falls back to the remaining one as hero" do
      restaurant = create(:restaurant, :with_photo, name: "Suerte")
      restaurant.photos.attach(io: StringIO.new(TestImages.png_1x1), filename: "second.png", content_type: "image/png")
      hero = restaurant.photos.attachments.max_by(&:id)
      restaurant.update!(hero_photo_id: hero.id)
      login_as(create(:user, :admin))

      delete "/restaurants/admin/restaurants/#{restaurant.id}/photos/#{hero.id}"

      restaurant.reload
      expect(restaurant.photos.attachments.size).to eq(1)
      expect(restaurant.hero_photo_id).to be_nil
      expect(restaurant.hero_photo).to be_present
    end

    it "searches the catalog from the admin page" do
      create(:restaurant, name: "Franklin Barbecue", cuisine: "Barbecue")
      create(:restaurant, name: "Uchi", cuisine: "Sushi")
      login_as(create(:user, :admin))

      get "/admin", params: { restaurant_q: "barbecue" }

      expect(response.body).to include("Franklin Barbecue")
      expect(response.body).not_to include(">Uchi<")
    end
  end
end
