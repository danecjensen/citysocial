module Messaging
  class ConversationStart
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :recipient_handle, :string
    attribute :body, :string
    attribute :context_path, :string
    attribute :context_label, :string

    validates :recipient_handle, :body, presence: true
    validates :body, length: { maximum: 2000 }
    validates :context_path, length: { maximum: 500 }, allow_blank: true
    validates :context_label, length: { maximum: 120 }, allow_blank: true
    validate :recipient_exists
    validate :recipient_is_not_sender
    validate :context_fields_are_paired
    validate :context_path_is_internal

    attr_reader :conversation

    def save(sender_id:)
      @sender_id = sender_id
      normalize_fields
      return false unless valid?

      ActiveRecord::Base.transaction do
        first_participant_id, second_participant_id = [sender_id, recipient_profile.id].sort
        @conversation = Conversation.find_or_create_by!(
          first_participant_id: first_participant_id,
          second_participant_id: second_participant_id
        )
        @conversation.update!(context_path: context_path, context_label: context_label) if context?
        @conversation.messages.create!(sender_id: sender_id, body: body)
      end

      true
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, e.record.errors.full_messages.to_sentence)
      false
    end

    private

    def context?
      context_path.present? && context_label.present?
    end

    def normalize_fields
      self.recipient_handle = recipient_handle.to_s.strip.delete_prefix("@")
      self.body = body.to_s.strip
      self.context_path = context_path.to_s.strip.presence
      self.context_label = context_label.to_s.strip.presence
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

    def context_fields_are_paired
      return if context_path.present? == context_label.present?

      errors.add(:base, "Conversation context needs both a path and label")
    end

    def context_path_is_internal
      return if context_path.blank? || context_path.match?(Conversation::CONTEXT_PATH_PATTERN)

      errors.add(:context_path, "must be an internal CitySocial path")
    end
  end
end
