require "rails_helper"

RSpec.describe "Communities", type: :request do
  def login_as(user, password: "s3cret-password")
    post "/login", params: { email: user.email, password: password }
  end

  it "lists communities publicly" do
    create(:community, name: "austinfood")
    get "/communities"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("c/austinfood")
  end

  it "requires login to create a community" do
    get "/communities/new"
    expect(response).to redirect_to("/login")
  end

  it "lets a logged-in user create a community, post, and vote" do
    login_as(create(:user))

    expect do
      post "/communities", params: { community: { name: "eastside", category: "general" } }
    end.to change(Communities::Community, :count).by(1)
    community = Communities::Community.last
    expect(response).to redirect_to("/communities/eastside")

    expect do
      post "/communities/#{community.slug}/posts", params: { post: { title: "First post here", body: "hi" } }
    end.to change(Communities::Post, :count).by(1)
    post_record = Communities::Post.last

    voter = create(:user)
    login_as(voter)
    expect do
      post "/communities/#{community.slug}/posts/#{post_record.id}/upvote"
    end.to change { post_record.reload.score }.from(1).to(2)
  end

  it "adds a comment to a post" do
    community = create(:community)
    post_record = create(:community_post, community: community)
    login_as(create(:user))

    expect do
      post "/communities/#{community.slug}/posts/#{post_record.id}/comments",
           params: { comment: { body: "Nice post" } }
    end.to change(Communities::Comment, :count).by(1)
  end

  it "blocks the module when it is disabled, then restores it" do
    create(:community, name: "austinfood")
    PlatformCore::Modules.disable!("communities")

    get "/communities"
    expect(response).to redirect_to("/")

    PlatformCore::Modules.enable!("communities")
    get "/communities"
    expect(response).to have_http_status(:ok)
  end
end
