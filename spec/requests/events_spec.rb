require "rails_helper"

RSpec.describe "Events", type: :request do
  describe "GET /events (this week's top 10)" do
    it "shows the ten best-scoring events in the week ahead and hides the rest" do
      create(:event, title: "Top Pick Headliner", score: 0.99, starts_at: 2.days.from_now)
      11.times { |i| create(:event, title: "Filler #{i}", score: 0.2, starts_at: 3.days.from_now) }
      create(:event, title: "Lowest Ranked Pick", score: 0.01, starts_at: 4.days.from_now)

      get "/events"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Top Pick Headliner")
      expect(response.body).not_to include("Lowest Ranked Pick")
    end

    it "renders an empty state when nothing is scheduled" do
      get "/events"
      expect(response.body).to include("No events yet this week")
    end
  end

  describe "GET /events/all (search archive)" do
    it "searches across every event by keyword and category" do
      create(:event, title: "Vintage Film Night", category: "film", starts_at: 2.days.from_now)
      create(:event, title: "Psych Rock Show", category: "music", starts_at: 40.days.from_now)

      get "/events/all"
      expect(response.body).to include("Vintage Film Night").and include("Psych Rock Show")

      get "/events/all", params: { q: "vintage" }
      expect(response.body).to include("Vintage Film Night")
      expect(response.body).not_to include("Psych Rock Show")

      get "/events/all", params: { category: "music" }
      expect(response.body).to include("Psych Rock Show")
      expect(response.body).not_to include("Vintage Film Night")
    end
  end

  describe "GET /events/e/:id" do
    it "shows a single event with its ticket link" do
      event = create(:event, title: "La Bohème", url: "https://austinopera.org/la-boheme")

      get "/events/e/#{event.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("La Bohème").and include("austinopera.org/la-boheme")
    end
  end

  it "is gated by the module flag" do
    create(:event, title: "Some Event", starts_at: 2.days.from_now)

    PlatformCore::Modules.disable!("events")
    get "/events"
    expect(response).to redirect_to("/")

    PlatformCore::Modules.enable!("events")
    get "/events"
    expect(response).to have_http_status(:ok)
  end
end
