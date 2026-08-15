require "rails_helper"

RSpec.describe "Home Feed 2.0", type: :request do
  def login_as(user)
    post "/login", params: { email: user.email, password: "s3cret-password" }
  end

  it "renders the prominent multi-format composer" do
    login_as(create(:user))

    get "/feed"

    page = Capybara.string(response.body)
    expect(response).to have_http_status(:ok)
    expect(page).to have_text("Share with your city")
    expect(page).to have_select(
      "What are you sharing?",
      options: [
        "A quick update", "Photos", "News article or link", "Poll", "Event", "Marketplace listing", "Pickup game"
      ]
    )
    expect(page).to have_field("Article or destination link")
    expect(page).to have_field("Photos")
  end

  it "posts an article and invokes safe rich-preview enrichment" do
    author = create(:user)
    login_as(author)
    allow(Feed::LinkPreview).to receive(:enrich) do |post_record|
      post_record.update!(
        preview_title: "Transit plan explained",
        preview_description: "The important details for local riders.",
        preview_site_name: "Local News"
      )
    end

    expect do
      post "/feed/posts", params: {
        post: {
          kind: "link",
          body: "This changes the bus route near us.",
          url: "https://news.example/transit"
        }
      }
    end.to change(Feed::Post, :count).by(1)

    article = Feed::Post.last
    expect(response).to redirect_to("/feed/posts/#{article.id}")
    expect(Feed::LinkPreview).to have_received(:enrich).with(article)

    get "/feed/posts/#{article.id}"
    expect(response.body).to include("Transit plan explained", "Local News", "Read the full story")
  end

  it "creates a photo post and a poll, then accepts a vote" do
    author = create(:user)
    voter = create(:user)
    login_as(author)
    photo = Rack::Test::UploadedFile.new(
      StringIO.new(TestImages.png_1x1),
      "image/png",
      true,
      original_filename: "block-party.png"
    )

    post "/feed/posts", params: { post: { kind: "photo", body: "Block party", photos: [photo] } }
    expect(Feed::Post.last.photos).to be_attached

    post "/feed/posts", params: {
      post: {
        kind: "poll",
        title: "Where should cleanup start?",
        poll_option_one: "Creek trail",
        poll_option_two: "Pocket park"
      }
    }
    poll = Feed::Post.last
    expect(poll.poll_options.pluck(:label)).to eq(["Creek trail", "Pocket park"])

    login_as(voter)
    post "/feed/posts/#{poll.id}/poll_votes", params: { option_id: poll.poll_options.first.id }
    expect(poll.poll_votes.where(user_id: voter.id)).to exist
  end

  it "supports detail comments, reactions, saves, sharing, and a saved feed" do
    author = create(:user)
    resident = create(:user)
    post_record = Feed::PublishPost.call(source: "web", author_id: author.id, body: "Need a ladder this weekend").post
    login_as(resident)

    post "/feed/posts/#{post_record.id}/comments", params: { comment: { body: "I have one." } }
    post "/feed/posts/#{post_record.id}/reaction", params: { kind: "helpful" }
    post "/feed/posts/#{post_record.id}/save"

    get "/feed/posts/#{post_record.id}"
    page = Capybara.string(response.body)
    expect(page).to have_text("I have one.")
    expect(page).to have_css("button[aria-label='React helpful'][aria-pressed='true']", text: "Helpful")
    expect(page).to have_text("Copy link")

    get "/feed", params: { filter: "saved" }
    expect(response.body).to include("Need a ladder this weekend")
  end

  it "allows only the author to edit or delete" do
    author = create(:user)
    other = create(:user)
    post_record = Feed::PublishPost.call(source: "web", author_id: author.id, body: "Original").post

    login_as(other)
    patch "/feed/posts/#{post_record.id}", params: { post: { body: "Taken over" } }
    expect(response).to redirect_to("/feed/posts/#{post_record.id}")
    expect(post_record.reload.body).to eq("Original")

    login_as(author)
    patch "/feed/posts/#{post_record.id}", params: { post: { body: "Updated" } }
    expect(post_record.reload.body).to eq("Updated")
    expect { delete "/feed/posts/#{post_record.id}" }.to change(Feed::Post, :count).by(-1)
  end
end
