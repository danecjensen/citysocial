require "rails_helper"

RSpec.describe "Google sign-in", type: :request do
  let(:auth_hash) do
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-abc",
      info: { email: "ada@example.com", name: "Ada Lovelace" }
    )
  end

  around do |example|
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = auth_hash
    example.run
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  it "offers a Google button on the login and signup pages" do
    get "/login"
    expect(response.body).to include("Continue with Google")
    expect(response.body).to include("/auth/google_oauth2")

    get "/signup"
    expect(response.body).to include("Continue with Google")
  end

  it "creates and signs in a new user from the callback" do
    allow(PlatformCore::Analytics).to receive(:identify)
    allow(PlatformCore::Analytics).to receive(:capture)

    expect { get "/auth/google_oauth2/callback" }
      .to change(PlatformCore::User, :count).by(1)

    expect(response).to redirect_to("/")
    user = PlatformCore::User.last
    expect(session[:user_id]).to eq(user.id)
    expect(PlatformCore::Analytics).to have_received(:capture).with(
      "user signed up",
      user_id: user,
      properties: { authentication_method: "google" }
    )
  end

  it "links the Google identity to an existing account with the same email" do
    allow(PlatformCore::Analytics).to receive(:capture)
    existing = create(:user, email: "ada@example.com")

    expect { get "/auth/google_oauth2/callback" }
      .not_to change(PlatformCore::User, :count)

    expect(response).to redirect_to("/")
    expect(existing.reload.provider).to eq("google_oauth2")
    expect(PlatformCore::Analytics).to have_received(:capture).with(
      "user logged in",
      user_id: existing,
      properties: { authentication_method: "google" }
    )
  end

  it "redirects to login when the identity is unusable" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "google-xyz", info: { email: "" }
    )

    get "/auth/google_oauth2/callback"

    expect(response).to redirect_to("/login")
    expect(session[:user_id]).to be_nil
  end

  it "redirects to login when the provider handshake fails" do
    get "/auth/failure"

    expect(response).to redirect_to("/login")
    follow_redirect!
    expect(response.body).to include("Google sign-in")
  end
end
