require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "signup" do
    it "creates a user and logs them in" do
      allow(PlatformCore::Analytics).to receive(:identify)
      allow(PlatformCore::Analytics).to receive(:capture)

      expect do
        post "/signup", params: {
          user: {
            handle: "newbie",
            email: "newbie@example.com",
            password: "s3cret-password",
            password_confirmation: "s3cret-password"
          }
        }
      end.to change(PlatformCore::User, :count).by(1)

      follow_redirect! # "/" -> redirect to "/feed"
      follow_redirect! # "/feed" -> rendered, now authenticated
      expect(response.body).to include("newbie")
      user = PlatformCore::User.find_by!(handle: "newbie")
      expect(PlatformCore::Analytics).to have_received(:identify).with(user)
      expect(PlatformCore::Analytics).to have_received(:capture).with(
        "user signed up",
        user_id: user,
        properties: { authentication_method: "password" }
      )
    end

    it "rejects mismatched password confirmation" do
      expect do
        post "/signup", params: {
          user: {
            handle: "newbie",
            email: "newbie@example.com",
            password: "s3cret-password",
            password_confirmation: "nope"
          }
        }
      end.not_to change(PlatformCore::User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "login / logout" do
    let!(:user) do
      create(:user, email: "dane@example.com", password: "right-password",
                    password_confirmation: "right-password")
    end

    it "logs in with valid credentials" do
      allow(PlatformCore::Analytics).to receive(:identify)
      allow(PlatformCore::Analytics).to receive(:capture)

      post "/login", params: { email: "dane@example.com", password: "right-password" }
      expect(response).to redirect_to("/")
      expect(PlatformCore::Analytics).to have_received(:capture).with(
        "user logged in",
        user_id: user,
        properties: { authentication_method: "password" }
      )
    end

    it "rejects invalid credentials" do
      post "/login", params: { email: "dane@example.com", password: "wrong" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "logs out" do
      allow(PlatformCore::Analytics).to receive(:capture)

      post "/login", params: { email: "dane@example.com", password: "right-password" }
      delete "/logout"
      expect(response).to redirect_to("/login")
      expect(PlatformCore::Analytics).to have_received(:capture).with(
        "user logged out",
        user_id: user
      )
    end
  end

  describe "protected feed" do
    it "redirects anonymous users to login" do
      get "/feed"
      expect(response).to redirect_to("/login")
    end
  end
end
