require "rails_helper"

RSpec.describe "Feed", type: :request do
  def login_as(user, password: "s3cret-password")
    post "/login", params: { email: user.email, password: password }
  end

  it "requires login to view the feed" do
    get "/feed"
    expect(response).to redirect_to("/login")
  end

  it "renders a post composer for a logged-in resident" do
    login_as(create(:user))

    get "/feed"

    expect(response).to have_http_status(:ok)
    body = Capybara.string(response.body)
    expect(body).to have_css("form[action='/feed/posts'] textarea[name='post[body]']")
    expect(body).to have_css("form[action='/feed/posts'] button[type='submit']")
  end

  it "creates a post from the composer and shows it in the feed" do
    user = create(:user)
    login_as(user)

    expect do
      post "/feed/posts", params: { post: { body: "Live music at Zilker tonight" } }
    end.to change(Feed::Post, :count).by(1)

    created = Feed::Post.last
    expect(created.author_id).to eq(user.id)
    expect(created.body).to eq("Live music at Zilker tonight")
    expect(response).to redirect_to("/feed/posts")

    follow_redirect!
    expect(response.body).to include("Live music at Zilker tonight")
  end

  it "publishes feed.post_created so followers can be notified" do
    events = []
    PlatformCore::EventBus.subscribe("feed.post_created", ->(_name, payload) { events << payload })
    user = create(:user)
    login_as(user)

    post "/feed/posts", params: { post: { body: "Neighborhood cleanup Saturday" } }

    expect(events.last).to include(post_id: Feed::Post.last.id, author_id: user.id)
  end

  it "rejects a blank post without a 500 and creates nothing" do
    login_as(create(:user))

    expect do
      post "/feed/posts", params: { post: { body: "   " } }
    end.not_to change(Feed::Post, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to match(/Body can\S*t be blank/)
  end
end
