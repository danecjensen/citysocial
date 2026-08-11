module Notifications
  class Notification < ApplicationRecord
    SUPPORTED_EVENTS = %w[
      feed.post_created
      communities.post_created
      marketplace.listing_created
      feedback.submission_status_changed
    ].freeze

    validates :recipient_id, :actor_id, :event_name, :source_id, :message, :target_path, presence: true
    validates :event_name, inclusion: { in: SUPPORTED_EVENTS }
    validates :target_path, format: { with: %r{\A/(?!/)}, message: "must be an internal path" }
    validates :source_id, uniqueness: { scope: %i[recipient_id event_name] }

    scope :recent, -> { order(created_at: :desc) }
    scope :unread, -> { where(read_at: nil) }

    def actor
      PlatformCore::Graph.user(actor_id)
    end

    def unread?
      read_at.nil?
    end

    def mark_read!
      update!(read_at: Time.current) if unread?
    end
  end
end
