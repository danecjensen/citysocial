require "rails_helper"

RSpec.describe "Feedback", type: :request do
  def login_as(user, password: "s3cret-password")
    post "/login", params: { email: user.email, password: password }
  end

  it "browses, searches, and filters the public feedback board" do
    idea = create(:feedback_submission, title: "Saved marketplace searches", kind: "idea", area: "marketplace")
    create(:feedback_submission, title: "Feed page jumps", kind: "issue", area: "feed")

    get "/feedback"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(idea.title).and include("Feed page jumps")

    get "/feedback", params: { q: "saved", kind: "idea", area: "marketplace" }
    expect(response.body).to include(idea.title)
    expect(response.body).not_to include("Feed page jumps")
  end

  it "requires login to share or support feedback" do
    submission = create(:feedback_submission)

    get "/feedback/submissions/new"
    expect(response).to redirect_to("/login")

    post "/feedback/submissions/#{submission.id}/toggle_support"
    expect(response).to redirect_to("/login")
  end

  it "prefills the current page and infers its app area from the global trigger" do
    login_as(create(:user))

    get "/marketplace", params: { q: "bike" }
    expect(response.body).to include("Give feedback about this page")
    expect(response.body).to include("page_url=%2Fmarketplace%2F%3Fq%3Dbike")

    get "/feedback/submissions/new", params: { page_url: "/marketplace?q=bike" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to match(%r{<option selected="selected" value="marketplace">Marketplace</option>})
    expect(response.body).to include('value="/marketplace?q=bike"')
  end

  it "creates contextual feedback for the signed-in member" do
    user = create(:user)
    login_as(user)

    expect do
      post "/feedback/submissions", params: {
        submission: {
          kind: "issue",
          area: "marketplace",
          page_url: "/marketplace/old-bike",
          title: "The listing photo is missing",
          description: "The listing detail page shows a blank space where the photo should be."
        }
      }
    end.to change(Feedback::Submission, :count).by(1)

    submission = Feedback::Submission.last
    expect(submission.author_id).to eq(user.id)
    expect(submission.area).to eq("marketplace")
    expect(response).to redirect_to("/feedback/submissions/#{submission.id}")

    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("The listing photo is missing").and include("/marketplace/old-bike")
  end

  it "re-renders invalid feedback with inline errors" do
    login_as(create(:user))

    expect do
      post "/feedback/submissions", params: {
        submission: { kind: "idea", title: "No", description: "Too short", page_url: "javascript:alert(1)" }
      }
    end.not_to change(Feedback::Submission, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Title is too short")
    expect(response.body).to include("Page url must be an app path or an http(s) URL")
  end

  it "toggles one support per signed-in member" do
    submission = create(:feedback_submission)
    supporter = create(:user)
    login_as(supporter)

    expect do
      post "/feedback/submissions/#{submission.id}/toggle_support"
    end.to change { submission.reload.supports_count }.from(0).to(1)

    expect do
      post "/feedback/submissions/#{submission.id}/toggle_support"
    end.to change { submission.reload.supports_count }.from(1).to(0)
  end

  it "reflects the viewer's support state via aria-pressed on the support toggle" do
    supported = create(:feedback_submission, title: "Backed idea")
    unsupported = create(:feedback_submission, title: "Fresh idea")
    supporter = create(:user)
    login_as(supporter)
    post "/feedback/submissions/#{supported.id}/toggle_support"

    get "/feedback"
    list = Capybara.string(response.body)
    expect(list).to have_css("button[aria-label='Remove support'][aria-pressed='true']")
    expect(list).to have_css("button[aria-label='Support this feedback'][aria-pressed='false']")

    get "/feedback/submissions/#{supported.id}"
    expect(Capybara.string(response.body)).to have_css("button[aria-pressed='true']")

    get "/feedback/submissions/#{unsupported.id}"
    expect(Capybara.string(response.body)).to have_css("button[aria-pressed='false']")
  end

  it "lets admins triage feedback from the admin page and blocks non-admins" do
    submission = create(:feedback_submission, title: "A useful product idea for triage")

    login_as(create(:user))
    get "/feedback/admin"
    expect(response).to redirect_to("/")

    login_as(create(:user, :admin))
    get "/admin"
    expect(response.body).to include("A useful product idea for triage")

    patch "/feedback/admin/submissions/#{submission.id}",
          params: { submission: { status: "in_progress" }, feedback_status: "open" }
    expect(submission.reload.status).to eq("in_progress")
    expect(response).to redirect_to("/admin?feedback_status=open#section-feedback")
  end

  it "filters the admin feedback section by status" do
    create(:feedback_submission, title: "An open idea worth building")
    create(:feedback_submission, title: "A finished idea worth shipping", status: "completed")
    login_as(create(:user, :admin))

    get "/admin", params: { feedback_status: "completed" }

    expect(response.body).to include("A finished idea worth shipping")
    expect(response.body).not_to include("An open idea worth building")
  end

  it "blocks the module when disabled, then restores it" do
    create(:feedback_submission)
    PlatformCore::Modules.disable!("feedback")

    get "/feedback"
    expect(response).to redirect_to("/")

    PlatformCore::Modules.enable!("feedback")
    get "/feedback"
    expect(response).to have_http_status(:ok)
  end
end
