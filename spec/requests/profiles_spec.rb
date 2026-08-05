require "rails_helper"
require "base64"

RSpec.describe "Public resident profiles", type: :request do
  let!(:user) do
    create(
      :user,
      handle: "dane",
      email: "private@example.com",
      display_name: "Dane Jensen",
      neighborhood: "Hyde Park",
      bio: "Building things for Austin."
    )
  end

  after { PlatformCore::EventBus.reset! }

  it "shows only public profile information to anonymous visitors" do
    get "/people/dane"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Dane Jensen", "@dane", "Hyde Park", "Building things for Austin.")
    expect(response.body).not_to include("private@example.com")
    expect(response.body).not_to include("password_digest")
  end

  it "renders a useful empty state for a resident without a bio" do
    user.update!(display_name: nil, neighborhood: nil, bio: nil)

    get "/people/dane"

    expect(response.body).to include("This resident is keeping it simple")
  end

  it "requires login to edit a profile" do
    get "/profile/edit"

    expect(response).to redirect_to("/login")
  end

  it "lets the signed-in resident update only public fields and publishes a safe event" do
    events = []
    PlatformCore::EventBus.subscribe("platform_core.profile_updated", ->(_name, payload) { events << payload })
    sign_in(user)

    patch "/profile", params: {
      user: {
        display_name: "Dane J.",
        neighborhood: "North Loop",
        bio: "Local builder.",
        email: "exposed@example.com",
        avatar: avatar_upload
      }
    }

    expect(response).to redirect_to("/people/dane")
    expect(user.reload).to have_attributes(
      display_name: "Dane J.",
      neighborhood: "North Loop",
      bio: "Local builder.",
      email: "private@example.com"
    )
    expect(user.avatar).to be_attached
    expect(events).to contain_exactly(
      user_id: user.id,
      changed_fields: %w[avatar bio display_name neighborhood]
    )
    expect(events.to_s).not_to include("private@example.com")
  end

  it "rejects a non-image avatar with an inline error" do
    sign_in(user)

    patch "/profile", params: {
      user: { avatar: avatar_upload(content: "not an image", filename: "avatar.gif", content_type: "image/gif") }
    }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Avatar must be a JPEG, PNG, or WebP image")
    expect(user.reload.avatar).not_to be_attached
  end

  def sign_in(account)
    post "/login", params: { email: account.email, password: "s3cret-password" }
  end

  def avatar_upload(content: valid_png, filename: "avatar.png", content_type: "image/png")
    Rack::Test::UploadedFile.new(
      StringIO.new(content),
      content_type,
      true,
      original_filename: filename
    )
  end

  def valid_png
    Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
    )
  end
end
