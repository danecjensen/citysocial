require "rails_helper"

RSpec.describe "Neighbor Help", type: :request do
  let(:requester) { create(:user, handle: "asker", display_name: "Austin Asker") }
  let(:helper) { create(:user, handle: "helper", display_name: "Helpful Neighbor") }

  after { PlatformCore::EventBus.reset! }

  it "lets anyone browse current favors by category and neighborhood with a useful empty state" do
    matching = create(
      :neighbor_help_request,
      requester: requester,
      title: "Library phone setup",
      category: "tech_help",
      neighborhood: "North Loop"
    )
    create(:neighbor_help_request, title: "Park cleanup", category: "outdoor_help", neighborhood: "Mueller")

    get "/neighbor_help", params: { category: "tech_help", neighborhood: "north" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(matching.title, "North Loop", "Open")
    expect(response.body).not_to include("Park cleanup")

    get "/neighbor_help", params: { category: "errand" }
    expect(response.body).to include("No matching favors right now")
  end

  it "requires login to post and renders safety errors without creating a request" do
    get "/neighbor_help/requests/new"
    expect(response).to redirect_to("/login")

    sign_in(requester)
    post "/neighbor_help/requests", params: {
      request: {
        title: "Unsafe favor",
        details: "Call 512-555-0199 for paid electrical work.",
        category: "other",
        neighborhood: "North Loop",
        starts_at: 1.day.from_now.strftime("%Y-%m-%d %H:%M"),
        ends_at: (1.day.from_now + 2.hours).strftime("%Y-%m-%d %H:%M"),
        estimated_minutes: 45,
        no_cash_confirmed: false
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Do not include an email address or phone number",
                                     "Favor scope cannot include payment")
    expect(NeighborHelp::Request.count).to eq(0)
  end

  it "creates a public-safe favor and shows the requester commitment" do
    sign_in(requester)
    post "/neighbor_help/requests", params: {
      request: {
        title: "Phone setup at the library",
        details: "Help me turn on larger text and organize two home-screen apps.",
        category: "tech_help",
        neighborhood: "North Loop",
        starts_at: 2.days.from_now.strftime("%Y-%m-%d %H:%M"),
        ends_at: (2.days.from_now + 90.minutes).strftime("%Y-%m-%d %H:%M"),
        estimated_minutes: 45,
        logistics_notes: "Meet at a public library desk after claiming.",
        no_cash_confirmed: true
      }
    }

    request = NeighborHelp::Request.last
    expect(response).to redirect_to("/neighbor_help/requests/#{request.id}")
    follow_redirect!
    expect(response.body).to include("Phone setup at the library", "Austin Asker", "No money",
                                     "Waiting for one neighbor")
  end

  it "enforces one helper, supports release, and lets only the requester close the loop" do
    request = create(:neighbor_help_request, requester: requester)
    another = create(:user, handle: "another")

    sign_in(helper)
    post "/neighbor_help/requests/#{request.id}/claim"
    expect(request.reload).to have_attributes(status: "claimed", helper_id: helper.id)
    expect(response).to redirect_to("/neighbor_help/requests/#{request.id}")

    sign_in(another)
    post "/neighbor_help/requests/#{request.id}/claim"
    expect(flash[:alert]).to eq("This favor is no longer available.")
    patch "/neighbor_help/requests/#{request.id}/complete"
    expect(request.reload).to be_claimed

    sign_in(helper)
    delete "/neighbor_help/requests/#{request.id}/claim"
    expect(request.reload).to have_attributes(status: "open", helper_id: nil)

    request.claim!(helper.id)
    sign_in(requester)
    patch "/neighbor_help/requests/#{request.id}/complete"
    expect(request.reload).to be_completed
  end

  it "accepts a report once and gives only admins the hide-or-dismiss queue" do
    request = create(:neighbor_help_request, requester: requester)
    admin = create(:user, admin: true)

    sign_in(helper)
    post "/neighbor_help/requests/#{request.id}/reports", params: {
      report: { reason: "unsafe_scope", details: "This appears to ask for risky work." }
    }
    expect(request.reload.moderation_state).to eq("reported")
    expect(request.reports.count).to eq(1)

    post "/neighbor_help/requests/#{request.id}/reports", params: {
      report: { reason: "spam" }
    }
    expect(request.reports.count).to eq(1)

    get "/neighbor_help/admin/requests"
    expect(response).to redirect_to("/")

    sign_in(admin)
    get "/neighbor_help/admin/requests"
    expect(response.body).to include(request.title, "Helpful Neighbor", "Unsafe scope")

    patch "/neighbor_help/admin/requests/#{request.id}", params: { request: { moderation_state: "hidden" } }
    expect(request.reload).to be_hidden
    expect(request.reports.first.reload.status).to eq("reviewed")

    get "/neighbor_help/requests/#{request.id}"
    expect(response).to have_http_status(:ok)

    sign_out
    get "/neighbor_help/requests/#{request.id}"
    expect(response).to have_http_status(:not_found)

    sign_in(requester)
    get "/neighbor_help/requests/#{request.id}"
    expect(response.body).to include("hidden from public discovery")
  end

  def sign_in(user)
    post "/login", params: { email: user.email, password: "s3cret-password" }
  end

  def sign_out
    delete "/logout"
  end
end
