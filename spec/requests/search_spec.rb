require "rails_helper"

RSpec.describe "Global public search", type: :request do
  it "replaces the marketplace-only nav form and renders an accessible blank state" do
    get "/search"

    expect(response).to have_http_status(:ok)
    page = Capybara.string(response.body)
    expect(page).to have_css("form[action='/search'] input[name='q'][aria-label='Search CitySocial']")
    expect(page).to have_css("h1", text: "Search CitySocial")
    expect(page).to have_text("Search across the city")
  end

  it "groups active listings and future events with canonical links and source labels" do
    listing = create(:listing, title: "Vintage Nightstand", price: 45, location: "North Loop")
    event = create(:event, title: "Vintage Night Market", venue: "Republic Square", starts_at: 2.days.from_now)
    create(:listing, title: "Vintage Sold Item", status: :sold)
    create(:event, title: "Vintage Past Event", starts_at: 2.days.ago)

    get "/search", params: { q: "vintage" }

    page = Capybara.string(response.body)
    expect(page).to have_css("h2", text: "Marketplace")
    expect(page).to have_css("a[href='/marketplace/#{listing.slug}']", text: listing.title)
    expect(page).to have_css("a[href='/marketplace?q=vintage']", text: "See all Marketplace results")
    expect(page).to have_css("h2", text: "Events")
    expect(page).to have_css("a[href='/events/e/#{event.id}']", text: event.title)
    expect(page).to have_css("a[href='/events/all?q=vintage']", text: "See all Events results")
    expect(page).to have_no_text("Vintage Sold Item")
    expect(page).to have_no_text("Vintage Past Event")
  end

  it "allows an explicit result-type filter" do
    create(:listing, title: "Neighborhood Jazz Records")
    create(:event, title: "Neighborhood Jazz Night")

    get "/search", params: { q: "neighborhood jazz", type: "event" }

    expect(response.body).to include("Neighborhood Jazz Night")
    expect(response.body).not_to include("Neighborhood Jazz Records")
  end

  it "shows a disabled source without querying or leaking its rows" do
    create(:event, title: "Hidden City Concert")
    PlatformCore::Modules.disable!("events")

    get "/search", params: { q: "hidden city", type: "event" }

    expect(response.body).to include("Search sources are disabled")
    expect(response.body).not_to include("Hidden City Concert")
  end

  it "keeps successful groups visible when one provider fails" do
    create(:listing, title: "Resilient City Bicycle")
    allow(Events::SearchProvider).to receive(:call).and_raise("database shard unavailable")

    get "/search", params: { q: "resilient city" }

    expect(response.body).to include("Resilient City Bicycle")
    expect(response.body).to include("This source could not be searched")
    expect(response.body).not_to include("database shard unavailable")
  end

  it "renders a useful no-results state" do
    get "/search", params: { q: "nothing matches this" }

    expect(response.body).to include("No public results found")
  end
end
