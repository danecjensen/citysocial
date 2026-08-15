require "rails_helper"

RSpec.describe "Shared calendar", type: :request do
  def login_as(user)
    post "/login", params: { email: user.email, password: "s3cret-password" }
  end

  it "renders a public month grid with attached event images and category filters" do
    visible = create(
      :shared_calendar_event,
      :with_image,
      title: "Waterfront Jazz Night",
      category: "music",
      starts_at: Time.zone.local(2026, 9, 12, 19)
    )
    create(
      :shared_calendar_event,
      title: "Neighborhood Potluck",
      category: "community",
      starts_at: Time.zone.local(2026, 9, 14, 18)
    )

    get "/shared_calendar", params: { month: "2026-09", category: "music" }

    page = Capybara.string(response.body)
    expect(response).to have_http_status(:ok)
    expect(page).to have_text("Community Calendar").and have_text("September 2026")
    expect(page).to have_text("Waterfront Jazz Night")
    expect(page).to have_no_text("Neighborhood Potluck")
    expect(page).to have_css("img[src^='/rails/active_storage/blobs/redirect/'][alt='Waterfront Jazz Night']")
    expect(page).to have_css("[role='grid'][aria-label='September 2026 calendar']")
    expect(visible.image).to be_attached
  end

  it "requires membership to add an event" do
    get "/shared_calendar/new"

    expect(response).to redirect_to("/login")
  end

  it "creates an event with an image and redirects to its public page" do
    author = create(:user)
    login_as(author)
    upload = Rack::Test::UploadedFile.new(
      StringIO.new(TestImages.png_1x1),
      "image/png",
      true,
      original_filename: "concert.png"
    )

    expect do
      post "/shared_calendar", params: {
        event: {
          title: "Courtyard Concert",
          category: "music",
          starts_at: 3.days.from_now,
          ends_at: 3.days.from_now + 2.hours,
          venue_name: "Central Library",
          location: "710 W Cesar Chavez St",
          description: "Bring a blanket.",
          image: upload
        }
      }
    end.to change(SharedCalendar::Event, :count).by(1)

    event = SharedCalendar::Event.last
    expect(event.author_id).to eq(author.id)
    expect(event.image).to be_attached
    expect(response).to redirect_to("/shared_calendar/#{event.id}")
  end

  it "shows validation errors inline" do
    login_as(create(:user))

    post "/shared_calendar", params: {
      event: {
        title: "Impossible timing",
        category: "other",
        starts_at: 2.days.from_now,
        ends_at: 1.day.from_now
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Ends at must be after the start time")
  end

  it "lets only the contributor edit and remove the event" do
    owner = create(:user)
    event = create(:shared_calendar_event, author: owner, title: "Original title")

    login_as(create(:user))
    patch "/shared_calendar/#{event.id}", params: { event: { title: "Taken over" } }
    expect(response).to redirect_to("/shared_calendar/#{event.id}")
    expect(event.reload.title).to eq("Original title")

    login_as(owner)
    patch "/shared_calendar/#{event.id}", params: { event: { title: "Updated title" } }
    expect(event.reload.title).to eq("Updated title")

    expect { delete "/shared_calendar/#{event.id}" }.to change(SharedCalendar::Event, :count).by(-1)
  end

  it "blocks the module when disabled and restores it" do
    PlatformCore::Modules.disable!("shared_calendar")

    get "/shared_calendar"
    expect(response).to redirect_to("/")

    PlatformCore::Modules.enable!("shared_calendar")
    get "/shared_calendar"
    expect(response).to have_http_status(:ok)
  ensure
    PlatformCore::Modules.enable!("shared_calendar")
  end
end
