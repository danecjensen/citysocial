module Messaging
  class ConversationStart
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :recipient_handle, :string
    attribute :body, :string

    validates :recipient_handle, :body, presence: true
    validates :body, length: { maximum: 2000 }
    validate :recipient_exists
    validate :recipient_is_not_sender

    attr_reader :conversation

    def save(sender_id:)
      @sender_id = sender_id
      normalize_fields
      return false unless valid?

      ActiveRecord::Base.transaction do
        first_participant_id, second_participant_id = [sender_id, recipient_profile.id].sort
        @conversation = Conversation.create_or_find_by!(
          first_participant_id: first_participant_id,
          second_participant_id: second_participant_id
        )
        @conversation.messages.create!(sender_id: sender_id, body: body)
      end

      true
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, e.record.errors.full_messages.to_sentence)
      false
    end

    private

    def normalize_fields
      self.recipient_handle = recipient_handle.to_s.strip.delete_prefix("@")
      self.body = body.to_s.strip
    end

    def recipient_profile
      @recipient_profile ||= PlatformCore::Graph.public_profile_by_handle(recipient_handle)
    end

    def recipient_exists
      errors.add(:recipient_handle, "does not match a resident") unless recipient_profile
    end

    def recipient_is_not_sender
      return unless recipient_profile && @sender_id
      return unless recipient_profile.id == @sender_id

      errors.add(:recipient_handle, "must be another resident")
    end
  end
end
