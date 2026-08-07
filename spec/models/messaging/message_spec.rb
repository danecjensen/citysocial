require "rails_helper"

RSpec.describe Messaging::Message, type: :model do
  it "accepts only a conversation participant as sender" do
    conversation = create(:messaging_conversation)
    outsider = create(:user)

    message = build(:messaging_message, conversation: conversation, sender_id: outsider.id)

    expect(message).not_to be_valid
    expect(message.errors[:sender_id]).to include("must belong to the conversation")
  end

  it "rejects blank and oversized private content" do
    conversation = create(:messaging_conversation)

    blank_message = build(:messaging_message, conversation: conversation, body: "   ")
    oversized_message = build(:messaging_message, conversation: conversation, body: "x" * 2001)

    expect(blank_message).not_to be_valid
    expect(blank_message.errors).to include(:body)
    expect(oversized_message).not_to be_valid
    expect(oversized_message.errors).to include(:body)
  end

  it "updates conversation activity and publishes a content-free event" do
    first_user = create(:user)
    second_user = create(:user)
    conversation = create(
      :messaging_conversation,
      first_participant: first_user,
      second_participant: second_user
    )
    allow(PlatformCore::EventBus).to receive(:publish)

    message = create(
      :messaging_message,
      conversation: conversation,
      sender_id: first_user.id,
      body: "Private meetup details"
    )

    expect(conversation.reload.last_message_at).to be_within(1.second).of(message.created_at)
    expect(PlatformCore::EventBus).to have_received(:publish).with(
      "messaging.message_created",
      message_id: message.id,
      conversation_id: conversation.id,
      sender_id: first_user.id,
      recipient_id: second_user.id
    )
  end
end
