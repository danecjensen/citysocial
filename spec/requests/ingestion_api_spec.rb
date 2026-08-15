require "rails_helper"

RSpec.describe "Ingestion API", type: :request do
  let(:user) { create(:user) }
  let(:issued) { PlatformCore::ApiTokens.issue!(source: "newsblur-cli", user_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{issued.token}" } }

  describe "authentication" do
    it "rejects requests without a bearer token" do
      post "/api/v1/posts", params: { external_id: "story-1", body: "Austin update" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to include("Bearer")
      expect(response.parsed_body).to eq("error" => "unauthorized")
    end

    it "rejects revoked bearer tokens" do
      PlatformCore::ApiTokens.revoke!(issued.id)

      post "/api/v1/posts", params: { external_id: "story-1", body: "Austin update" }, headers: headers, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/posts" do
    it "creates an attributed post and returns 201" do
      post "/api/v1/posts",
           params: {
             external_id: "story-1",
             title: "City budget",
             url: "https://example.com/city-budget",
             source: "spoofed-source",
             author_id: -1
           },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("status" => "created")
      expect(Feed::Post.last).to have_attributes(
        source: "newsblur-cli", external_id: "story-1", author_id: user.id
      )
    end

    it "returns 200 duplicate for a retry" do
      payload = { external_id: "story-1", body: "Austin update" }

      2.times { post "/api/v1/posts", params: payload, headers: headers, as: :json }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("status" => "duplicate")
      expect(Feed::Post.count).to eq(1)
    end

    it "requires an external ID for API idempotency" do
      post "/api/v1/posts", params: { body: "Austin update" }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to include("status" => "invalid")
      expect(Feed::Post.count).to eq(0)
    end
  end

  describe "POST /api/v1/events" do
    let(:event_payload) do
      {
        external_id: "event-42",
        title: "Austin Night Market",
        venue: "Republic Square",
        starts_at: "2026-08-20T19:00:00-05:00",
        category: "food",
        why: "A distinctive outdoor market with local vendors.",
        ticket_urgency: "advance tickets recommended",
        age_limit: "All ages",
        source: "spoofed-source"
      }
    end

    it "creates an attributed event and returns 201" do
      post "/api/v1/events", params: event_payload, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("status" => "created")
      expect(Events::Event.last).to have_attributes(
        source: "newsblur-cli",
        external_id: "event-42",
        why: "A distinctive outdoor market with local vendors.",
        ticket_urgency: "advance tickets recommended",
        age_limit: "All ages"
      )
    end

    it "returns duplicate for an exact retry and updated for a correction" do
      post "/api/v1/events", params: event_payload, headers: headers, as: :json
      post "/api/v1/events", params: event_payload, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("status" => "duplicate")

      post "/api/v1/events", params: event_payload.merge(price: "$10"), headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("status" => "updated")
      expect(Events::Event.last.price).to eq("$10")
      expect(Events::Event.count).to eq(1)
    end

    it "returns validation errors without writing malformed input" do
      post "/api/v1/events",
           params: { external_id: "event-42", title: "No start time" },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to include("status" => "invalid")
      expect(Events::Event.count).to eq(0)
    end

    it "rejects unsafe event URLs" do
      post "/api/v1/events",
           params: event_payload.merge(url: "javascript:alert(1)"),
           headers: headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include("Url must be an HTTP or HTTPS URL")
      expect(Events::Event.count).to eq(0)
    end
  end
end
