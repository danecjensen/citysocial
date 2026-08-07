module Messaging
  class Message < ApplicationRecord
    belongs_to :conversation,
               class_name: "Messaging::Conversation",
               inverse_of: :messages

    validates :sender_id, :body, presence: true
    validates :body, length: { maximum: 2000 }
    validate :sender_belongs_to_conversation

    normalizes :body, with: ->(body) { body&.strip }

    after_create :update_conversation_activity
    after_create_commit :publish_created

    def sender
      PlatformCore::Graph.user(sender_id)
    end

    def recipient_id
      conversation.other_participant_id(sender_id)
    end

    private

    def sender_belongs_to_conversation
      return if sender_id.blank? || conversation.blank?
      return if conversation.participant?(sender_id)

      errors.add(:sender_id, "must belong to the conversation")
    end

    def update_conversation_activity
      conversation.update!(
        last_message_at: created_at,
        first_participant_archived_at: nil,
        second_participant_archived_at: nil
      )
    end

    def publish_created
      PlatformCore::EventBus.publish(
        "messaging.message_created",
        message_id: id,
        conversation_id: conversation_id,
        sender_id: sender_id,
        recipient_id: recipient_id
      )
    end
  end
end
