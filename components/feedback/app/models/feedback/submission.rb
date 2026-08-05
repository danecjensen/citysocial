require "uri"

module Feedback
  class Submission < ApplicationRecord
    KINDS = %w[idea issue other].freeze
    STATUSES = %w[open planned in_progress completed closed].freeze

    KIND_LABELS = {
      "idea" => "Product idea",
      "issue" => "Problem",
      "other" => "Other feedback"
    }.freeze

    STATUS_LABELS = {
      "open" => "Open",
      "planned" => "Planned",
      "in_progress" => "In progress",
      "completed" => "Completed",
      "closed" => "Closed"
    }.freeze

    KIND_BADGES = {
      "idea" => :brand,
      "issue" => :danger,
      "other" => :neutral
    }.freeze

    STATUS_BADGES = {
      "open" => :neutral,
      "planned" => :agave,
      "in_progress" => :brand,
      "completed" => :success,
      "closed" => :neutral
    }.freeze

    has_many :supports,
             class_name: "Feedback::Support",
             dependent: :destroy,
             inverse_of: :submission

    validates :author_id, :kind, :status, :title, :description, presence: true
    validates :kind, inclusion: { in: KINDS }
    validates :status, inclusion: { in: STATUSES }
    validates :title, length: { in: 5..120 }
    validates :description, length: { in: 10..5000 }
    validates :area, length: { maximum: 80 }, allow_blank: true
    validates :page_url, length: { maximum: 2048 }, allow_blank: true
    validate :page_url_is_safe

    scope :recent, -> { order(created_at: :desc, id: :desc) }
    scope :most_supported, -> { order(supports_count: :desc, created_at: :desc, id: :desc) }

    after_create_commit :publish_created
    after_update_commit :publish_status_changed, if: :saved_change_to_status?

    def author
      PlatformCore::Graph.user(author_id)
    end

    def supported_by?(user_id)
      user_id.present? && supports.exists?(user_id: user_id)
    end

    def kind_label
      KIND_LABELS.fetch(kind)
    end

    def status_label
      STATUS_LABELS.fetch(status)
    end

    def kind_badge
      KIND_BADGES.fetch(kind)
    end

    def status_badge
      STATUS_BADGES.fetch(status)
    end

    private

    def page_url_is_safe
      return if page_url.blank?
      return if internal_path? || http_url?

      errors.add(:page_url, "must be an app path or an http(s) URL")
    rescue URI::InvalidURIError
      errors.add(:page_url, "must be a valid URL")
    end

    def internal_path?
      page_url.start_with?("/") && !page_url.start_with?("//")
    end

    def http_url?
      uri = URI.parse(page_url)
      %w[http https].include?(uri.scheme) && uri.host.present?
    end

    def publish_created
      PlatformCore::EventBus.publish(
        "feedback.submission_created",
        submission_id: id,
        author_id: author_id,
        kind: kind,
        area: area
      )
    end

    def publish_status_changed
      PlatformCore::EventBus.publish(
        "feedback.submission_status_changed",
        submission_id: id,
        author_id: author_id,
        status: status
      )
    end
  end
end
