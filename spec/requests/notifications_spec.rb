require "rails_helper"

RSpec.describe "Notifications", type: :request do
  def login_as(user)
    post "/login", params: { email: user.email, password: "s3cret-password" }
  end

  it "requires login and renders the empty state" do
    get "/notifications"
    expect(response).to redirect_to("/login")

    login_as(create(:user))
    get "/notifications"

    expect(response).to have_http_status(:ok)
    expect(Capybara.string(response.body)).to have_text("You're all caught up")
  end

  it "shows only the resident's notifications and exposes an unread badge" do
    resident = create(:user)
    other_resident = create(:user)
    visible = create(:notification, recipient: resident, message: "Visible notification")
    create(:notification, recipient: other_resident, message: "Private notification")
    login_as(resident)

    get "/notifications"

    expect(response.body).to include(visible.message).and include("Notifications").and include("New")
    expect(response.body).not_to include("Private notification")
  end

  it "marks owned notifications read and refuses another resident's notification" do
    resident = create(:user)
    owned = create(:notification, recipient: resident, target_path: "/feed")
    private_notification = create(:notification)
    login_as(resident)

    patch "/notifications/#{owned.id}/read"
    expect(response).to redirect_to("/feed")
    expect(owned.reload).not_to be_unread

    patch "/notifications/#{private_notification.id}/read"
    expect(response).to have_http_status(:not_found)
    expect(private_notification.reload).to be_unread
  end

  it "marks all of the resident's notifications read without changing another inbox" do
    resident = create(:user)
    owned = create_list(:notification, 2, recipient: resident)
    private_notification = create(:notification)
    login_as(resident)

    patch "/notifications/read_all"

    expect(response).to redirect_to("/notifications/")
    expect(owned.map { |notification| notification.reload.read_at }).to all(be_present)
    expect(private_notification.reload).to be_unread
  end
end
