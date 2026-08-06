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

  it "sorts comments by conversation order by default and score when requested" do
    community = create(:community)
    post_record = create(:community_post, community: community)
    author = create(:user)
    older_low_score = Communities::Comment.create!(post: post_record, author_id: author.id, body: "Older low score",
                                                   created_at: 2.hours.ago)
    newer_top_score = Communities::Comment.create!(post: post_record, author_id: author.id, body: "Newer top score",
                                                   created_at: 1.hour.ago)
    older_low_score.update_column(:score, 1)
    newer_top_score.update_column(:score, 8)
    scores = [older_low_score, newer_top_score].to_h { |comment| [comment.id, comment.score] }

    get "/communities/#{community.slug}/posts/#{post_record.id}"
    expect(response.body.index("Older low score")).to be < response.body.index("Newer top score")
    page = Capybara.string(response.body)
    expect(page).to have_css("nav[aria-label='Comment sort'] a", text: "New")
    expect(page).to have_css("nav[aria-label='Comment sort'] a", text: "Top")

    get "/communities/#{community.slug}/posts/#{post_record.id}", params: { sort: "top" }
    expect(response.body.index("Newer top score")).to be < response.body.index("Older low score")
    expect([older_low_score.reload, newer_top_score.reload].to_h do |comment|
      [comment.id, comment.score]
    end).to eq(scores)
  end

  it "labels the vote buttons on a post for assistive tech" do
    community = create(:community)
    post_record = create(:community_post, community: community)
    login_as(create(:user))

    get "/communities/#{community.slug}/posts/#{post_record.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('aria-label="Upvote"')
    expect(response.body).to include('aria-label="Downvote"')
  end

  it "highlights the vote arrow matching the current user's vote on the post list and show pages" do
    community = create(:community, name: "eastside")
    post_record = create(:community_post, community: community)
    voter = create(:user)
    login_as(voter)
    post_record.cast_vote(voter.id, 1)

    get "/communities/#{community.slug}"
    list = Capybara.string(response.body)
    expect(list).to have_css("button[aria-label='Upvote'][aria-pressed='true'].bg-brand-600")
    expect(list).to have_css("button[aria-label='Downvote'][aria-pressed='false']")

    get "/communities/#{community.slug}/posts/#{post_record.id}"
    show = Capybara.string(response.body)
    expect(show).to have_css("button[aria-label='Upvote'][aria-pressed='true'].bg-brand-600")
  end

  it "highlights the downvoted comment for the voter" do
    community = create(:community)
    post_record = create(:community_post, community: community)
    comment = Communities::Comment.create!(post: post_record, body: "A comment", author_id: create(:user).id)
    voter = create(:user)
    login_as(voter)
    comment.cast_vote(voter.id, -1)

    get "/communities/#{community.slug}/posts/#{post_record.id}"
    show = Capybara.string(response.body)
    expect(show).to have_css("button[aria-label='Downvote'][aria-pressed='true'].bg-danger")
  end

  it "renders the neutral vote state for a logged-in user who has not voted" do
    community = create(:community)
    post_record = create(:community_post, community: community)
    login_as(create(:user))

    get "/communities/#{community.slug}/posts/#{post_record.id}"
    show = Capybara.string(response.body)
    expect(show).to have_css("button[aria-label='Upvote'][aria-pressed='false']")
    expect(show).to have_no_css("button[aria-pressed='true']")
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
