module Messaging
  class Conversation < ApplicationRecord
    CONTEXT_PATH_PATTERN = %r{\A/(?!/)[^\\\x00-\x1F\x7F]*\z}

    has_many :messages,
             -> { order(created_at: :asc, id: :asc) },
             class_name: "Messaging::Message",
             dependent: :destroy,
             inverse_of: :conversation

    validates :first_participant_id, :second_participant_id, presence: true
    validates :first_participant_id, uniqueness: { scope: :second_participant_id }
    validates :context_path, length: { maximum: 500 }, allow_blank: true
    validates :context_label, length: { maximum: 120 }, allow_blank: true
    validate :participants_are_different
    validate :context_fields_are_paired
    validate :context_path_is_internal

    before_validation :canonicalize_participants
    before_validation :normalize_context

    scope :for_participant, lambda { |user_id|
      where(first_participant_id: user_id).or(where(second_participant_id: user_id))
    }
    scope :active_for, lambda { |user_id|
      where(
        "(first_participant_id = :user_id AND first_participant_archived_at IS NULL) OR " \
        "(second_participant_id = :user_id AND second_participant_archived_at IS NULL)",
        user_id: user_id
      )
    }
    scope :archived_for, lambda { |user_id|
      where(
        "(first_participant_id = :user_id AND first_participant_archived_at IS NOT NULL) OR " \
        "(second_participant_id = :user_id AND second_participant_archived_at IS NOT NULL)",
        user_id: user_id
      )
    }
    scope :recent, -> { order(last_message_at: :desc, updated_at: :desc, id: :desc) }

    def self.with_other_participant_ids(user_id, participant_ids)
      ids = Array(participant_ids).map(&:to_i)
      return none if ids.empty?

      where(first_participant_id: user_id, second_participant_id: ids)
        .or(where(second_participant_id: user_id, first_participant_id: ids))
    end

    def self.between(first_user_id, second_user_id)
      first_id, second_id = [first_user_id, second_user_id].map(&:to_i).sort
      where(first_participant_id: first_id, second_participant_id: second_id)
    end

    def participant?(user_id)
      participant_ids.include?(user_id.to_i)
    end

    def participant_ids
      [first_participant_id, second_participant_id]
    end

    def other_participant_id(user_id)
      return unless participant?(user_id)

      participant_ids.find { |participant_id| participant_id != user_id.to_i }
    end

    def other_participant(user_id)
      PlatformCore::Graph.user(other_participant_id(user_id))
    end

    def unread_count_for(user_id)
      return 0 unless participant?(user_id)

      messages.where(read_at: nil).where.not(sender_id: user_id).count
    end

    def mark_read_for!(user_id)
      return 0 unless participant?(user_id)

      messages.where(read_at: nil).where.not(sender_id: user_id).update_all(read_at: Time.current)
    end

    def archived_for?(user_id)
      attribute = archive_attribute_for(user_id)
      attribute ? public_send(attribute).present? : false
    end

    def context?
      context_path.present? && context_label.present?
    end

    def archive_for!(user_id)
      attribute = archive_attribute_for(user_id)
      return false unless attribute

      update!(attribute => Time.current)
    end

    def restore_for!(user_id)
      attribute = archive_attribute_for(user_id)
      return false unless attribute

      update!(attribute => nil)
    end

    private

    def archive_attribute_for(user_id)
      return :first_participant_archived_at if first_participant_id == user_id.to_i

      :second_participant_archived_at if second_participant_id == user_id.to_i
    end

    def canonicalize_participants
      return if first_participant_id.blank? || second_participant_id.blank?

      self.first_participant_id, self.second_participant_id = participant_ids.map(&:to_i).sort
    end

    def normalize_context
      self.context_path = context_path.to_s.strip.presence
      self.context_label = context_label.to_s.strip.presence
    end

    def context_fields_are_paired
      return if context_path.present? == context_label.present?

      errors.add(:base, "Conversation context needs both a path and label")
    end

    def context_path_is_internal
      return if context_path.blank? || context_path.match?(CONTEXT_PATH_PATTERN)

      errors.add(:context_path, "must be an internal CitySocial path")
    end

    def participants_are_different
      return if first_participant_id.blank? || second_participant_id.blank?
      return unless first_participant_id == second_participant_id

      errors.add(:second_participant_id, "must be a different resident")
    end
  end
end
