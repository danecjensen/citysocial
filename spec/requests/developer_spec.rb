require "csv"
require "rails_helper"

RSpec.describe "Developer portal", type: :request do
  def login_as(user, password: "s3cret-password")
    post "/login", params: { email: user.email, password: password }
  end

  describe "authorization" do
    it "redirects anonymous visitors to login" do
      get "/developer"

      expect(response).to redirect_to("/login")
    end

    it "redirects non-admin members away" do
      login_as(create(:user))

      get "/developer"

      expect(response).to redirect_to("/")
    end

    it "allows administrators" do
      login_as(create(:user, :admin))

      get "/developer"

      expect(response).to have_http_status(:ok)
    end
  end

  context "when signed in as an administrator" do
    before { login_as(create(:user, :admin)) }

    describe "GET /developer" do
      it "lists every application model but excludes framework records" do
        get "/developer"

        expect(response.body).to include("Communities::Post")
        expect(response.body).to include("Feed::Post")
        expect(response.body).to include("PlatformCore::User")
        expect(response.body).not_to include("ActiveStorage::Blob")
      end

      it "uses distinct table identifiers for models with the same route key" do
        get "/developer"

        expect(response.body).to include("/developer/communities_posts")
        expect(response.body).to include("/developer/feed_posts")
      end
    end

    describe "GET /developer/:model" do
      it "renders all database columns and each record in a table" do
        restaurant = create(:restaurant, name: "Juan in a Million")

        get "/developer/restaurants_restaurants"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Juan in a Million")
        Restaurants::Restaurant.column_names.each do |column|
          expect(response.body).to include(column)
        end
        expect(response.body).to include("/developer/restaurants_restaurants/#{restaurant.id}")
      end

      it "sorts only by allowlisted database columns" do
        create(:restaurant, name: "Alpha")
        create(:restaurant, name: "Zulu")

        get "/developer/restaurants_restaurants", params: { sort: "name", dir: "asc" }

        expect(response.body.index("Alpha")).to be < response.body.index("Zulu")

        get "/developer/restaurants_restaurants", params: { sort: "name desc; drop table users" }

        expect(response).to have_http_status(:ok)
      end

      it "redirects unknown identifiers without constantizing them" do
        get "/developer/not_a_model"

        expect(response).to redirect_to("/developer/")
      end
    end

    describe "GET /developer/:model.csv" do
      it "downloads every column and record for one model" do
        now = Time.current
        Restaurants::Restaurant.insert_all!(
          101.times.map do |index|
            { name: "CSV Restaurant #{index}", cuisine: "Various", area: "Austin", created_at: now, updated_at: now }
          end
        )

        get "/developer/restaurants_restaurants.csv"

        rows = CSV.parse(response.body, headers: true)
        expect(response.media_type).to eq("text/csv")
        expect(response.headers.fetch("Content-Disposition")).to include("restaurants_restaurants-")
        expect(rows.headers).to eq(Restaurants::Restaurant.column_names)
        expect(rows.length).to eq(101)
        expect(rows.pluck("name")).to include("CSV Restaurant 0", "CSV Restaurant 100")
      end
    end

    describe "CRUD" do
      it "creates, reads, updates, and deletes a record" do
        expect do
          post "/developer/restaurants_restaurants", params: {
            restaurant: { name: "Nixta Taqueria", cuisine: "Mexican", area: "East Austin", elo: 1510 }
          }
        end.to change(Restaurants::Restaurant, :count).by(1)

        restaurant = Restaurants::Restaurant.find_by!(name: "Nixta Taqueria")
        expect(response).to redirect_to("/developer/restaurants_restaurants/#{restaurant.id}")

        get "/developer/restaurants_restaurants/#{restaurant.id}"
        expect(response.body).to include("Nixta Taqueria")

        patch "/developer/restaurants_restaurants/#{restaurant.id}", params: {
          restaurant: { name: "Nixta", cuisine: "Mexican", area: "East Austin", elo: 1525 }
        }
        expect(response).to redirect_to("/developer/restaurants_restaurants/#{restaurant.id}")
        expect(restaurant.reload.attributes).to include("name" => "Nixta", "elo" => 1525)

        expect do
          delete "/developer/restaurants_restaurants/#{restaurant.id}"
        end.to change(Restaurants::Restaurant, :count).by(-1)
        expect(response).to redirect_to("/developer/restaurants_restaurants")
      end

      it "renders model validation failures" do
        post "/developer/restaurants_restaurants", params: { restaurant: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Name can&#39;t be blank")
      end

      it "supports virtual secure-password fields while hiding password digests" do
        get "/developer/platform_core_users/new"

        expect(response.body).to include('name="user[password]"')
        expect(response.body).not_to include('name="user[password_digest]"')

        expect do
          post "/developer/platform_core_users", params: {
            user: {
              handle: "portal-user",
              email: "portal-user@example.com",
              password: "safe-password",
              password_confirmation: "safe-password",
              admin: false
            }
          }
        end.to change(PlatformCore::User, :count).by(1)

        expect(PlatformCore::User.find_by!(handle: "portal-user").authenticate("safe-password")).to be_present
      end
    end
  end
end
