require "rails_helper"

RSpec.describe Messaging::Conversation, type: :model do
  it "stores each resident pair once in canonical order" do
    first_user = create(:user)
    second_user = create(:user)

    conversation = described_class.create!(
      first_participant_id: second_user.id,
      second_participant_id: first_user.id
    )

    expect(conversation.participant_ids).to eq([first_user.id, second_user.id].sort)
    expect(described_class.between(second_user.id, first_user.id)).to contain_exactly(conversation)

    duplicate = described_class.new(
      first_participant_id: first_user.id,
      second_participant_id: second_user.id
    )
    expect(duplicate).not_to be_valid
  end

  it "rejects a conversation with oneself" do
    user = create(:user)
    conversation = described_class.new(
      first_participant_id: user.id,
      second_participant_id: user.id
    )

    expect(conversation).not_to be_valid
    expect(conversation.errors[:second_participant_id]).to include("must be a different resident")
  end

  it "counts and marks only received unread messages" do
    first_user = create(:user)
    second_user = create(:user)
    conversation = create(
      :messaging_conversation,
      first_participant: first_user,
      second_participant: second_user
    )
    received = create(:messaging_message, conversation: conversation, sender_id: second_user.id)
    create(:messaging_message, conversation: conversation, sender_id: first_user.id)

    expect(conversation.unread_count_for(first_user.id)).to eq(1)

    conversation.mark_read_for!(first_user.id)
    expect(received.reload.read_at).to be_present
    expect(conversation.messages.where(sender_id: first_user.id).pick(:read_at)).to be_nil

    outsider = create(:user)
    expect(conversation.unread_count_for(outsider.id)).to eq(0)
    expect(conversation.mark_read_for!(outsider.id)).to eq(0)
  end
end
