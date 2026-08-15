require "rails_helper"

RSpec.describe "PostHog browser analytics", type: :request do
  around do |example|
    config = Rails.configuration.x.posthog
    original = {
      enabled: config.enabled,
      project_token: config.project_token,
      host: config.host
    }

    config.enabled = true
    config.project_token = "phc_browser_test"
    config.host = "https://eu.i.posthog.com"
    example.run
  ensure
    config.enabled = original[:enabled]
    config.project_token = original[:project_token]
    config.host = original[:host]
  end

  it "loads the current web SDK with privacy-first defaults" do
    get "/about"

    expect(response.body).to include("phc_browser_test", "https://eu.i.posthog.com")
    expect(response.body).to include(
      "strict_script_versioning: true",
      "capture_pageview: \"history_change\"",
      "mask_all_text: true",
      "mask_all_element_attributes: true",
      "maskAllInputs: true",
      "maskTextSelector: \"*\""
    )
  end

  it "puts the same non-PII user identity on Turbo-rendered pages" do
    user = create(:user, email: "private@example.com", handle: "public-handle")
    post "/login", params: { email: user.email, password: "s3cret-password" }

    get "/feed"

    body = Capybara.string(response.body).find("body")
    expect(body["data-posthog-distinct-id"]).to eq("user_#{user.id}")
    expect(JSON.parse(body["data-posthog-person-properties"])).to include(
      "account_type" => "resident"
    )
    expect(body["data-posthog-person-properties"]).not_to include(user.email, user.handle)
  end

  it "emits no browser SDK when disabled" do
    Rails.configuration.x.posthog.enabled = false

    get "/about"

    expect(response.body).not_to include("posthog.init", "phc_browser_test")
  end
end
