module Messaging
  class Conversation < ApplicationRecord
    has_many :messages,
             -> { order(created_at: :asc, id: :asc) },
             class_name: "Messaging::Message",
             dependent: :destroy,
             inverse_of: :conversation

    validates :first_participant_id, :second_participant_id, presence: true
    validates :first_participant_id, uniqueness: { scope: :second_participant_id }
    validate :participants_are_different

    before_validation :canonicalize_participants

    scope :for_participant, lambda { |user_id|
      where(first_participant_id: user_id).or(where(second_participant_id: user_id))
    }
    scope :recent, -> { order(last_message_at: :desc, updated_at: :desc, id: :desc) }

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

    private

    def canonicalize_participants
      return if first_participant_id.blank? || second_participant_id.blank?

      self.first_participant_id, self.second_participant_id = participant_ids.map(&:to_i).sort
    end

    def participants_are_different
      return if first_participant_id.blank? || second_participant_id.blank?
      return unless first_participant_id == second_participant_id

      errors.add(:second_participant_id, "must be a different resident")
    end
  end
end
