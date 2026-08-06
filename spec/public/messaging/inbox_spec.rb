require "rails_helper"

RSpec.describe Messaging::Inbox do
  it "exposes only the resident's received unread count" do
    resident = create(:user)
    neighbor = create(:user)
    outsider = create(:user)
    conversation = create(
      :messaging_conversation,
      first_participant: resident,
      second_participant: neighbor
    )
    other_conversation = create(
      :messaging_conversation,
      first_participant: neighbor,
      second_participant: outsider
    )

    create(:messaging_message, conversation: conversation, sender_id: neighbor.id)
    create(:messaging_message, conversation: conversation, sender_id: resident.id)
    create(:messaging_message, conversation: other_conversation, sender_id: neighbor.id)
    create(:messaging_message, conversation: conversation, sender_id: neighbor.id, read_at: Time.current)

    expect(described_class.unread_count(resident.id)).to eq(1)
  end
end
