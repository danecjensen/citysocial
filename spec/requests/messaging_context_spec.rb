require "rails_helper"

RSpec.describe "Messaging context", type: :request do
  let!(:resident) { create(:user, handle: "resident") }
  let!(:neighbor) { create(:user, handle: "neighbor", display_name: "Helpful Neighbor") }

  it "starts a contextual message from a marketplace listing" do
    listing = create(:listing, author_id: neighbor.id, title: "Vintage commuter bike")
    sign_in(resident)

    get "/marketplace/#{listing.to_param}"

    entry = Capybara.string(response.body).find_link("Message seller")
    params = Rack::Utils.parse_nested_query(URI(entry[:href]).query)
    expect(params).to include(
      "recipient" => "neighbor",
      "context_path" => "/marketplace/#{listing.to_param}",
      "context_label" => "Vintage commuter bike"
    )
  end

  it "starts a contextual message from a community post" do
    community = create(:community)
    post = create(:community_post, community: community, author_id: neighbor.id, title: "Saturday cleanup crew")
    sign_in(resident)

    get "/communities/#{community.to_param}/posts/#{post.id}"

    entry = Capybara.string(response.body).find_link("Message author")
    params = Rack::Utils.parse_nested_query(URI(entry[:href]).query)
    expect(params).to include(
      "recipient" => "neighbor",
      "context_path" => "/communities/#{community.to_param}/posts/#{post.id}",
      "context_label" => "Saturday cleanup crew"
    )
  end

  it "preserves context through compose and links back from the thread" do
    context = {
      recipient: "neighbor",
      context_path: "/marketplace/vintage-bike",
      context_label: "Vintage commuter bike"
    }
    sign_in(resident)

    get "/messaging/conversations/new", params: context
    page = Capybara.string(response.body)
    expect(page).to have_text("Vintage commuter bike")
    expect(page).to have_field(
      :messaging_conversation_start_context_path,
      with: "/marketplace/vintage-bike",
      type: :hidden,
      visible: :all
    )
    expect(page).to have_field(
      :messaging_conversation_start_context_label,
      with: "Vintage commuter bike",
      type: :hidden,
      visible: :all
    )

    post "/messaging/conversations", params: {
      messaging_conversation_start: context.except(:recipient).merge(
        recipient_handle: context[:recipient],
        body: "Is this still available?"
      )
    }

    conversation = Messaging::Conversation.last
    expect(conversation).to have_attributes(
      context_path: "/marketplace/vintage-bike",
      context_label: "Vintage commuter bike"
    )
    expect(response).to redirect_to("/messaging/conversations/#{conversation.id}")

    get "/messaging/conversations/#{conversation.id}"
    expect(Capybara.string(response.body)).to have_link(
      "View Vintage commuter bike",
      href: "/marketplace/vintage-bike"
    )
  end

  it "rejects external, protocol-relative, incomplete, and oversized context" do
    sign_in(resident)

    invalid_contexts = [
      { context_path: "https://example.com/listing", context_label: "External" },
      { context_path: "//example.com/listing", context_label: "Protocol relative" },
      { context_path: "/marketplace/vintage-bike", context_label: "" },
      { context_path: "/marketplace/vintage-bike", context_label: "x" * 121 }
    ]

    invalid_contexts.each do |context|
      expect do
        post "/messaging/conversations", params: {
          messaging_conversation_start: context.merge(
            recipient_handle: "neighbor",
            body: "Do not send this"
          )
        }
      end.not_to change(Messaging::Message, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    expect(Messaging::Conversation.count).to eq(0)
    expect(response.body).to include("Context label is too long")
  end

  def sign_in(user)
    post "/login", params: { email: user.email, password: "s3cret-password" }
  end
end
