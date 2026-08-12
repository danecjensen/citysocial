require "rails_helper"

RSpec.describe "Messaging", type: :request do
  let!(:resident) { create(:user, handle: "resident", display_name: "Resident One") }
  let!(:neighbor) { create(:user, handle: "neighbor", display_name: "Helpful Neighbor") }

  it "requires login for the messaging product" do
    get "/messaging"
    expect(response).to redirect_to("/login")

    get "/messaging/conversations/new"
    expect(response).to redirect_to("/login")
  end

  it "shows an empty inbox and discovers messaging from another resident's profile" do
    sign_in(resident)

    get "/messaging"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No conversations yet", "Start a conversation")

    get "/people/neighbor"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Message resident")
    expect(response.body).to include("/messaging/conversations/new?recipient=neighbor")
  end

  it "starts one conversation, shows unread state to the recipient, and supports replies" do
    sign_in(resident)

    expect do
      post "/messaging/conversations", params: {
        messaging_conversation_start: {
          recipient_handle: "@neighbor",
          body: "Are you going to the block party?"
        }
      }
    end.to change(Messaging::Conversation, :count).by(1)
                                                  .and change(Messaging::Message, :count).by(1)

    conversation = Messaging::Conversation.last
    expect(response).to redirect_to("/messaging/conversations/#{conversation.id}")

    sign_in(neighbor)
    get "/messaging"
    expect(response.body).to include("1 unread", "Are you going to the block party?")

    get "/messaging/conversations/#{conversation.id}"
    expect(response).to have_http_status(:ok)
    expect(conversation.messages.first.reload.read_at).to be_present

    expect do
      post "/messaging/conversations/#{conversation.id}/messages", params: {
        message: { body: "Yes — see you there!" }
      }
    end.to change(Messaging::Message, :count).by(1)

    expect(response).to redirect_to("/messaging/conversations/#{conversation.id}")
    expect(conversation.messages.last.sender_id).to eq(neighbor.id)
  end

  it "reuses the existing participant pair instead of creating duplicate conversations" do
    conversation = create(
      :messaging_conversation,
      first_participant: resident,
      second_participant: neighbor
    )
    sign_in(resident)

    expect do
      post "/messaging/conversations", params: {
        messaging_conversation_start: {
          recipient_handle: "neighbor",
          body: "A second note in the same thread."
        }
      }
    end.not_to change(Messaging::Conversation, :count)

    expect(response).to redirect_to("/messaging/conversations/#{conversation.id}")
    expect(conversation.messages.reload.last.body).to eq("A second note in the same thread.")
  end

  it "rejects unknown and self recipients with inline errors" do
    sign_in(resident)

    post "/messaging/conversations", params: {
      messaging_conversation_start: { recipient_handle: "missing", body: "Hello there" }
    }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Recipient handle does not match a resident")

    post "/messaging/conversations", params: {
      messaging_conversation_start: { recipient_handle: "resident", body: "Note to self" }
    }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Recipient handle must be another resident")

    post "/messaging/conversations", params: {
      messaging_conversation_start: { recipient_handle: "neighbor", body: " " }
    }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Body can&#39;t be blank")
  end

  it "prevents non-participants from reading or writing a conversation" do
    outsider = create(:user)
    conversation = create(
      :messaging_conversation,
      first_participant: resident,
      second_participant: neighbor
    )
    sign_in(outsider)

    get "/messaging/conversations/#{conversation.id}"
    expect(response).to have_http_status(:not_found)

    post "/messaging/conversations/#{conversation.id}/messages", params: {
      message: { body: "I should not be here." }
    }
    expect(response).to have_http_status(:not_found)
  end

  it "lets each participant archive and restore a conversation without deleting history" do
    conversation = create(
      :messaging_conversation,
      first_participant: resident,
      second_participant: neighbor
    )
    create(:messaging_message, conversation: conversation, sender_id: neighbor.id, body: "Keep this history")
    sign_in(resident)

    patch "/messaging/conversations/#{conversation.id}/archive"
    expect(response).to redirect_to("/messaging/conversations")

    get "/messaging"
    expect(response.body).not_to include("Keep this history")

    get "/messaging/conversations", params: { view: "archived" }
    expect(response.body).to include("Archived messages", "Keep this history", "Restore")

    get "/messaging/conversations/#{conversation.id}"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Keep this history")

    patch "/messaging/conversations/#{conversation.id}/restore"
    expect(response).to redirect_to("/messaging/conversations?view=archived")

    get "/messaging"
    expect(response.body).to include("Keep this history")
  end

  it "keeps archive state private to one participant and rejects outsider archive actions" do
    outsider = create(:user)
    conversation = create(
      :messaging_conversation,
      first_participant: resident,
      second_participant: neighbor
    )
    create(:messaging_message, conversation: conversation, sender_id: resident.id, body: "Neighbor still sees this")
    sign_in(resident)

    patch "/messaging/conversations/#{conversation.id}/archive"

    sign_in(neighbor)
    get "/messaging"
    expect(response.body).to include("Neighbor still sees this")

    sign_in(outsider)
    patch "/messaging/conversations/#{conversation.id}/archive"
    expect(response).to have_http_status(:not_found)
  end

  it "searches active and archived inboxes by public handle or display name" do
    artist = create(:user, handle: "artist", display_name: "Mural Painter")
    helpful_conversation = create(
      :messaging_conversation,
      first_participant: resident,
      second_participant: neighbor
    )
    artist_conversation = create(
      :messaging_conversation,
      first_participant: resident,
      second_participant: artist
    )
    create(:messaging_message, conversation: helpful_conversation, sender_id: neighbor.id, body: "Block party details")
    create(:messaging_message, conversation: artist_conversation, sender_id: artist.id, body: "Mural details")
    sign_in(resident)

    get "/messaging/conversations", params: { q: "helpful" }
    expect(response.body).to include("Helpful Neighbor", "Block party details")
    expect(response.body).not_to include("Mural Painter", "Mural details")

    helpful_conversation.archive_for!(resident.id)
    get "/messaging/conversations", params: { view: "archived", q: "neighbor" }
    expect(response.body).to include("Helpful Neighbor", "Block party details")
    expect(response.body).not_to include("Mural Painter", "Mural details")
  end

  it "returns an archived conversation to both inboxes when a participant replies" do
    conversation = create(
      :messaging_conversation,
      first_participant: resident,
      second_participant: neighbor
    )
    create(:messaging_message, conversation: conversation, sender_id: resident.id)
    conversation.archive_for!(resident.id)
    conversation.archive_for!(neighbor.id)
    sign_in(neighbor)

    post "/messaging/conversations/#{conversation.id}/messages", params: {
      message: { body: "This brings the thread back." }
    }

    expect(conversation.reload).not_to be_archived_for(resident.id)
    expect(conversation).not_to be_archived_for(neighbor.id)

    sign_in(resident)
    get "/messaging"
    expect(response.body).to include("This brings the thread back.")
  end

  it "blocks the module when disabled, then restores it" do
    sign_in(resident)
    PlatformCore::Modules.disable!("messaging")

    get "/messaging"
    expect(response).to redirect_to("/")

    PlatformCore::Modules.enable!("messaging")
    get "/messaging"
    expect(response).to have_http_status(:ok)
  end

  it "renders the resident's message inbox inline on their own profile" do
    conversation = create(
      :messaging_conversation,
      first_participant: neighbor,
      second_participant: resident
    )
    create(
      :messaging_message,
      conversation: conversation,
      sender_id: neighbor.id,
      body: "Are you going to the block party?",
      read_at: nil
    )

    sign_in(resident)
    get "/people/resident"

    doc = Capybara.string(response.body)
    expect(doc).to have_text("Messages")
    expect(doc).to have_text("1 unread message")
    expect(doc).to have_text("Helpful Neighbor")
    expect(doc).to have_text("Are you going to the block party?")
    expect(doc).to have_css("a[href='/messaging/conversations/#{conversation.id}']")
  end

  it "shows an empty inbox state on the profile when there are no conversations" do
    sign_in(resident)
    get "/people/resident"

    doc = Capybara.string(response.body)
    expect(doc).to have_text("No conversations yet")
    expect(doc).to have_link("New message", href: "/messaging/conversations/new")
  end

  it "keeps the personal message inbox off other residents' profiles" do
    sign_in(resident)

    get "/people/neighbor"

    doc = Capybara.string(response.body)
    expect(doc).to have_text("Message resident")
    expect(doc).to have_no_link("New message", href: "/messaging/conversations/new")
  end

  it "hides the inbox panel on the profile when the messaging module is disabled" do
    sign_in(resident)
    PlatformCore::Modules.disable!("messaging")

    get "/people/resident"
    expect(response.body).not_to include("/messaging/conversations/new")
  ensure
    PlatformCore::Modules.enable!("messaging")
  end

  def sign_in(user)
    post "/login", params: { email: user.email, password: "s3cret-password" }
  end
end
