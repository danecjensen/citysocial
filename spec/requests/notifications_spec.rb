require "rails_helper"

RSpec.describe "Notifications", type: :request do
  def login_as(user)
    post "/login", params: { email: user.email, password: "s3cret-password" }
  end

  # Counts queries against the users table so we can prove the actor lookup is
  # batched (constant) rather than one-per-row.
  def count_user_queries
    queries = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      next if payload[:name].to_s.include?("SCHEMA")

      queries += 1 if payload[:sql].to_s.match?(/platform_core_users/i)
    end
    yield
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
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

  it "shows feedback status changes to the submission author" do
    author = create(:user)
    Notifications::DeliverDirect.call(
      "feedback.submission_status_changed",
      { submission_id: 42, author_id: author.id, status: "planned" }
    )
    notification = Notifications::Notification.find_by!(recipient_id: author.id)
    login_as(author)

    get "/notifications"

    doc = Capybara.string(response.body)
    expect(doc).to have_text("Your feedback moved to Planned.")
    expect(doc).to have_css(
      "form[action='/notifications/#{notification.id}/read'] button[type='submit']",
      text: "View"
    )
  end

  it "resolves notification actors without an N+1 as the inbox grows" do
    small_resident = create(:user)
    3.times { create(:notification, recipient: small_resident, actor: create(:user)) }
    login_as(small_resident)
    small = count_user_queries { get "/notifications" }
    expect(response).to have_http_status(:ok)

    large_resident = create(:user)
    8.times { create(:notification, recipient: large_resident, actor: create(:user)) }
    login_as(large_resident)
    large = count_user_queries { get "/notifications" }
    expect(response).to have_http_status(:ok)

    # A per-row lookup would make `large` grow with the extra actors; a batch keeps it flat.
    expect(large).to eq(small)
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

  it "shows a red notification bubble in the nav with the unread count" do
    resident = create(:user, handle: "belle")
    create_list(:notification, 2, recipient: resident)
    login_as(resident)

    get "/people/belle"

    doc = Capybara.string(response.body)
    expect(doc).to have_css("a[aria-label='Notifications'][href='/notifications/']")
    expect(doc).to have_css("a[aria-label='Notifications'] span", text: "2")
  end

  it "shows the notification bell without a bubble when the resident is caught up" do
    resident = create(:user, handle: "quiet")
    login_as(resident)

    get "/people/quiet"

    doc = Capybara.string(response.body)
    expect(doc).to have_css("a[aria-label='Notifications'][href='/notifications/']")
    expect(doc).to have_no_css("a[aria-label='Notifications'] span")
  end

  it "hides the notification bell when the module is disabled" do
    resident = create(:user, handle: "muted")
    login_as(resident)
    PlatformCore::Modules.disable!("notifications")

    get "/people/muted"
    expect(response.body).not_to include("aria-label=\"Notifications\"")
  ensure
    PlatformCore::Modules.enable!("notifications")
  end

  it "no longer renders notifications inside the profile page body" do
    resident = create(:user, handle: "calm")
    create(:notification, recipient: resident)
    login_as(resident)

    get "/people/calm"

    # Notifications live on their own page now; only the nav bell links there.
    expect(response.body).not_to include("Updates and new activity across CitySocial")
  end
end
