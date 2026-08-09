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

  it "archives independently for each participant and restores the selected inbox" do
    first_user = create(:user)
    second_user = create(:user)
    conversation = create(
      :messaging_conversation,
      first_participant: first_user,
      second_participant: second_user
    )

    expect(conversation.archive_for!(first_user.id)).to be(true)
    expect(conversation.reload).to be_archived_for(first_user.id)
    expect(conversation).not_to be_archived_for(second_user.id)
    expect(described_class.archived_for(first_user.id)).to contain_exactly(conversation)
    expect(described_class.active_for(second_user.id)).to contain_exactly(conversation)

    expect(conversation.restore_for!(first_user.id)).to be(true)
    expect(conversation.reload).not_to be_archived_for(first_user.id)
    expect(described_class.active_for(first_user.id)).to contain_exactly(conversation)
  end

  it "does not archive or restore for a non-participant" do
    conversation = create(:messaging_conversation)
    outsider = create(:user)

    expect(conversation.archive_for!(outsider.id)).to be(false)
    expect(conversation.restore_for!(outsider.id)).to be(false)
    expect(conversation).not_to be_archived_for(outsider.id)
  end

  it "filters conversations by the other participant ids" do
    resident = create(:user)
    matching_neighbor = create(:user)
    other_neighbor = create(:user)
    matching = create(
      :messaging_conversation,
      first_participant: resident,
      second_participant: matching_neighbor
    )
    create(
      :messaging_conversation,
      first_participant: resident,
      second_participant: other_neighbor
    )

    expect(described_class.with_other_participant_ids(resident.id, [matching_neighbor.id])).to contain_exactly(matching)
    expect(described_class.with_other_participant_ids(resident.id, [])).to be_empty
  end

  it "accepts only paired, internal public context" do
    conversation = build(
      :messaging_conversation,
      context_path: " /marketplace/vintage-bike ",
      context_label: " Vintage bike "
    )

    expect(conversation).to be_valid
    expect(conversation.context_path).to eq("/marketplace/vintage-bike")
    expect(conversation.context_label).to eq("Vintage bike")
    expect(conversation).to be_context

    conversation.context_path = "https://example.com/phishing"
    expect(conversation).not_to be_valid
    expect(conversation.errors[:context_path]).to include("must be an internal CitySocial path")

    conversation.context_path = "/marketplace/vintage-bike"
    conversation.context_label = nil
    expect(conversation).not_to be_valid
    expect(conversation.errors[:base]).to include("Conversation context needs both a path and label")
  end
end
