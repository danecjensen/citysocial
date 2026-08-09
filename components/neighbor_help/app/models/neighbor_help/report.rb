module NeighborHelp
  class Report < ApplicationRecord
    REASONS = %w[unsafe_scope contact_or_address money_or_services spam other].freeze
    STATUSES = %w[pending reviewed dismissed].freeze

    belongs_to :request, class_name: "NeighborHelp::Request", inverse_of: :reports

    validates :reporter_id, presence: true, uniqueness: { scope: :request_id }
    validates :reason, inclusion: { in: REASONS }
    validates :status, inclusion: { in: STATUSES }
    validates :details, length: { maximum: 500 }, allow_blank: true
    validate :reporter_is_not_requester

    scope :pending, -> { where(status: "pending") }
    scope :recent, -> { order(created_at: :desc, id: :desc) }

    after_create_commit :flag_request

    private

    def reporter_is_not_requester
      errors.add(:reporter_id, "cannot report their own request") if request&.requester_id == reporter_id
    end

    def flag_request
      request.flag_reported!(reporter_id)
    end
  end
end
