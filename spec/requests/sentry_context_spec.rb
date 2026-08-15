require "rails_helper"

RSpec.describe "Sentry request context", type: :request do
  before do
    allow(Sentry).to receive(:set_user)
    allow(Sentry).to receive(:set_tags)
    allow(Sentry).to receive(:set_context)
  end

  it "attributes authenticated module requests by opaque user ID" do
    user = create(:user, email: "resident@example.com", password: "right-password",
                         password_confirmation: "right-password")

    post "/login", params: { email: user.email, password: "right-password" }
    get "/feed"

    expect(Sentry).to have_received(:set_user).with(id: user.id.to_s).at_least(:once)
    expect(Sentry).to have_received(:set_tags).with(
      app_module: "feed",
      authentication: "session"
    )
    expect(Sentry).to have_received(:set_context).with(
      "request",
      hash_including(request_id: kind_of(String))
    ).at_least(:once)
  end

  it "marks anonymous module requests without attaching identity" do
    get "/feed"

    expect(Sentry).to have_received(:set_user).with({})
    expect(Sentry).to have_received(:set_tags).with(
      app_module: "feed",
      authentication: "anonymous"
    )
  end

  it "attributes ingestion requests without exposing bearer tokens" do
    user = create(:user)
    issued = PlatformCore::ApiTokens.issue!(source: "newsblur-cli", user_id: user.id)

    post "/api/v1/posts",
         params: { body: "private post text" },
         headers: { "Authorization" => "Bearer #{issued.token}" },
         as: :json

    expect(Sentry).to have_received(:set_user).with(id: user.id.to_s)
    expect(Sentry).to have_received(:set_tags).with(
      app_module: "ingestion_api",
      authentication: "api_token",
      ingestion_source: "newsblur-cli"
    )
    expect(Sentry).to have_received(:set_context).with(
      "api_credential",
      hash_including(id: issued.id, source: "newsblur-cli", request_id: kind_of(String))
    )
  end
end
