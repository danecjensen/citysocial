require "rails_helper"

RSpec.describe "Events", type: :request do
  describe "GET /events (this week's top 10)" do
    it "shows the ten best-scoring events in the week ahead and hides the rest" do
      create(
        :event,
        title: "Top Pick Headliner",
        why: "A rare favorite-venue show.",
        score: 0.99,
        starts_at: 2.days.from_now
      )
      11.times { |i| create(:event, title: "Filler #{i}", score: 0.2, starts_at: 3.days.from_now) }
      create(:event, title: "Lowest Ranked Pick", score: 0.01, starts_at: 4.days.from_now)

      get "/events"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Top Pick Headliner")
      expect(response.body).to include("A rare favorite-venue show.")
      expect(response.body).not_to include("Lowest Ranked Pick")
    end

    it "renders an empty state when nothing is scheduled" do
      get "/events"
      expect(response.body).to include("No events yet this week")
    end

    it "provides a category placeholder when remote artwork fails" do
      create(:event, title: "Fragile Poster", image_url: "https://venue.example/missing.jpg")

      get "/events"

      page = Capybara.string(response.body)
      image = "[data-controller='remote-image'] img[data-remote-image-target='image']"
      placeholder = "[data-remote-image-target='placeholder'][hidden]"
      expect(page).to have_css("#{image}[data-action*='error->remote-image#showPlaceholder']")
      expect(page).to have_css(placeholder, text: "Image unavailable", visible: :all)
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
    it "shows a single event with a safe new-tab ticket link" do
      event = create(
        :event,
        title: "La Bohème",
        why: "Ambitious opera at a favorite venue.",
        ticket_urgency: "likely to sell out",
        age_limit: "All ages",
        url: "https://austinopera.org/la-boheme"
      )

      get "/events/e/#{event.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("La Bohème").and include("austinopera.org/la-boheme")
      expect(response.body).to include("Ambitious opera at a favorite venue.")
      expect(response.body).to include("likely to sell out").and include("All ages")
      page = Capybara.string(response.body)
      expect(page).to have_css(
        "a[href='https://austinopera.org/la-boheme'][target='_blank'][rel='noopener noreferrer']",
        text: "Tickets & details"
      )
      expect(page).to have_css("[data-controller='remote-image'] img[data-remote-image-target='image']")
      expect(page).to have_css(
        "[data-remote-image-target='placeholder'][hidden]",
        text: "Image unavailable",
        visible: :all
      )
    end

    it "renders the category placeholder immediately when no artwork was supplied" do
      event = create(:event, title: "Posterless Performance", image_url: nil, category: "performing_arts")

      get "/events/e/#{event.id}"

      page = Capybara.string(response.body)
      expect(page).to have_no_css("[data-controller='remote-image']")
      expect(page).to have_css("[role='img'][aria-label='No image available for Posterless Performance']")
      expect(page).to have_css("[role='img']", text: "Image unavailable")
    end
  end

  describe "calendar actions on the event page" do
    it "offers a Google Calendar link and an .ics download alongside the ticket link" do
      event = create(:event, title: "La Bohème", url: "https://austinopera.org/la-boheme")

      get "/events/e/#{event.id}"

      expect(response).to have_http_status(:ok)
      page = Capybara.string(response.body)
      # Ticket link still opens safely in a new tab (unchanged).
      expect(page).to have_css("a[href='https://austinopera.org/la-boheme'][target='_blank']")
      # Google Calendar link opens in a new tab.
      expect(page).to have_css(
        "a[href^='https://calendar.google.com/calendar/render'][target='_blank'][rel='noopener noreferrer']",
        text: "Google Calendar"
      )
      # Internal .ics download link.
      expect(page).to have_css("a[href='/events/e/#{event.id}/calendar']", text: "Download .ics")
    end
  end

  describe "public sharing on the event page" do
    it "shares the canonical CitySocial event URL while preserving ticket and calendar actions" do
      event = create(:event, title: "Austin Night Market", url: "https://tickets.example/night-market")

      get "/events/e/#{event.id}"

      expect(response).to have_http_status(:ok)
      page = Capybara.string(response.body)
      share = "[data-controller='share'][data-share-title-value='Austin Night Market']" \
              "[data-share-url-value='http://www.example.com/events/e/#{event.id}']"
      expect(page).to have_css("#{share} button[data-action='share#copy']", text: "Copy link")
      expect(page).to have_css("#{share} [data-share-target='native'][hidden]", text: "Share", visible: :all)
      expect(page).to have_no_css("[data-share-url-value='https://tickets.example/night-market']")
      expect(page).to have_css("a[href='https://tickets.example/night-market']", text: "Tickets & details")
      expect(page).to have_css("a[href='/events/e/#{event.id}/calendar']", text: "Download .ics")
    end
  end

  describe "GET /events/e/:id/calendar (ICS download)" do
    it "downloads a valid iCalendar file built from the event's fields" do
      event = create(
        :event,
        title: "Psych Rock Show",
        venue: "Hotel Vegas",
        starts_at: Time.zone.parse("2026-08-08T20:00:00-05:00"),
        ends_at: nil
      )

      get "/events/e/#{event.id}/calendar"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/calendar")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to include("psych-rock-show.ics")
      expect(response.body).to include("BEGIN:VCALENDAR").and include("BEGIN:VEVENT")
      expect(response.body).to include("SUMMARY:Psych Rock Show")
      expect(response.body).to include("DTSTART:20260809T010000Z")
      # ends_at was blank, so the defined 2h fallback is used.
      expect(response.body).to include("DTEND:20260809T030000Z")
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
