module NeighborHelp
  class Request < ApplicationRecord
    class TransitionError < StandardError; end

    CATEGORIES = %w[errand tech_help outdoor_help pickup_dropoff other].freeze
    STATUSES = %w[open claimed completed canceled].freeze
    MODERATION_STATES = %w[visible reported hidden].freeze
    CONTACT_PATTERN = /(?:\b[\w.+-]+@[\w.-]+\.\w+\b|\b(?:\+?1[\s.-]?)?\(?\d{3}\)?[\s.-]\d{3}[\s.-]\d{4}\b)/i
    ADDRESS_PATTERN = /
      \b\d{1,6}\s+[a-z0-9]+(?:\s+[a-z0-9]+){0,3}\s+
      (?:street|st|road|rd|avenue|ave|boulevard|blvd|drive|dr|lane|ln|court|ct|way)\b
    /ix
    PROHIBITED_PATTERN = /
      \b(?:emergency|911|medical|medication|childcare|babysit|passenger\s+ride|
      cash|payment|paid|reimburse(?:ment)?|ride|caregiving|personal\s+care|elder\s+care|
      in-home|inside\s+my\s+home|weapon|firearm|roofing|electrical|plumbing|gas\s+line|
      hazardous|heavy\s+lifting|ladder)\b
    /ix

    has_many :reports, class_name: "NeighborHelp::Report", dependent: :destroy, inverse_of: :request

    validates :requester_id, :title, :details, :category, :neighborhood, :starts_at, :ends_at,
              :estimated_minutes, presence: true
    validates :title, length: { maximum: 100 }
    validates :details, length: { maximum: 1200 }
    validates :neighborhood, length: { maximum: 80 }
    validates :logistics_notes, length: { maximum: 500 }, allow_blank: true
    validates :category, inclusion: { in: CATEGORIES }
    validates :status, inclusion: { in: STATUSES }
    validates :moderation_state, inclusion: { in: MODERATION_STATES }
    validates :estimated_minutes, numericality: { only_integer: true, in: 15..240 }
    validates :no_cash_confirmed, inclusion: { in: [true], message: "must be confirmed" }
    validate :window_is_safe
    validate :public_text_is_safe
    validate :helper_matches_status

    scope :publicly_visible, -> { where(moderation_state: %w[visible reported]) }
    scope :current, -> { where(status: %w[open claimed]).where(ends_at: Time.current..) }
    scope :by_category, ->(category) { where(category: category) }
    scope :in_neighborhood, lambda { |query|
      pattern = "%#{sanitize_sql_like(query.to_s.strip)}%"
      where("neighborhood ILIKE ?", pattern)
    }
    scope :on_date, ->(date) { where(starts_at: date.in_time_zone.all_day) }

    after_create_commit :announce_creation
    after_update_commit :announce_change, if: -> { @event_change_kind.present? }

    def requester
      PlatformCore::Graph.user(requester_id)
    end

    def helper
      PlatformCore::Graph.user(helper_id) if helper_id
    end

    def active?
      status.in?(%w[open claimed])
    end

    def open?
      status == "open"
    end

    def claimed?
      status == "claimed"
    end

    def completed?
      status == "completed"
    end

    def canceled?
      status == "canceled"
    end

    def hidden?
      moderation_state == "hidden"
    end

    def expired?
      active? && ends_at.past?
    end

    def display_status
      return "expired" if expired?
      return "hidden" if hidden?

      status
    end

    def claim!(resident_id)
      with_lock do
        return self if claimed? && helper_id == resident_id
        raise TransitionError, "You cannot claim your own request." if requester_id == resident_id
        raise TransitionError, "This favor is no longer available." unless open? && !expired? && !hidden?

        transition!(
          actor_id: resident_id,
          recipient_id: requester_id,
          change_kind: "claimed",
          attributes: { helper_id: resident_id, status: "claimed" }
        )
      end
      self
    end

    def release!(resident_id)
      with_lock do
        unless claimed? && helper_id == resident_id
          raise TransitionError,
                "Only the current helper can release this favor."
        end
        raise TransitionError, "This favor's time window has ended." if expired?

        transition!(
          actor_id: resident_id,
          recipient_id: requester_id,
          change_kind: "released",
          attributes: { helper_id: nil, status: "open" }
        )
      end
      self
    end

    def complete!(resident_id)
      with_lock do
        raise TransitionError, "Only the requester can complete this favor." unless requester_id == resident_id
        raise TransitionError, "Only a claimed favor can be completed." unless claimed?

        transition!(
          actor_id: resident_id,
          recipient_id: helper_id,
          change_kind: "completed",
          attributes: { status: "completed" }
        )
      end
      self
    end

    def cancel!(resident_id)
      with_lock do
        raise TransitionError, "Only the requester can cancel this favor." unless requester_id == resident_id
        raise TransitionError, "This favor is already closed." unless active?

        transition!(
          actor_id: resident_id,
          recipient_id: helper_id,
          change_kind: "canceled",
          attributes: { status: "canceled" }
        )
      end
      self
    end

    def flag_reported!(reporter_id)
      return if hidden? || moderation_state == "reported"

      transition!(
        actor_id: reporter_id,
        recipient_id: nil,
        change_kind: "reported",
        attributes: { moderation_state: "reported" }
      )
    end

    def moderate!(moderator_id:, state:)
      raise ArgumentError, "unsupported moderation state" unless state.in?(%w[visible hidden])

      transition!(
        actor_id: moderator_id,
        recipient_id: requester_id,
        change_kind: state == "hidden" ? "hidden" : "restored",
        attributes: { moderation_state: state }
      )
    end

    private

    def window_is_safe
      return if starts_at.blank? || ends_at.blank?

      errors.add(:starts_at, "must be in the future") if new_record? && !starts_at.future?
      errors.add(:ends_at, "must be after the start") unless ends_at > starts_at
      errors.add(:ends_at, "must be within 7 days of the start") if ends_at > starts_at + 7.days
    end

    def public_text_is_safe
      text = [title, neighborhood, details, logistics_notes].compact.join(" ")
      if text.match?(CONTACT_PATTERN)
        errors.add(:base,
                   "Do not include an email address or phone number; coordinate after a claim.")
      end
      if text.match?(ADDRESS_PATTERN)
        errors.add(:base,
                   "Use only a neighborhood or public landmark, never an exact street address.")
      end
      return unless text.match?(PROHIBITED_PATTERN)

      errors.add(:base,
                 "Favor scope cannot include payment, emergencies, care work, rides, " \
                 "regulated trades, or hazardous work.")
    end

    def helper_matches_status
      errors.add(:helper_id, "is required for a claimed favor") if claimed? && helper_id.blank?
      errors.add(:helper_id, "must be empty for an open favor") if open? && helper_id.present?
    end

    def transition!(actor_id:, recipient_id:, change_kind:, attributes:)
      @event_actor_id = actor_id
      @event_recipient_id = recipient_id
      @event_change_kind = change_kind
      update!(attributes)
    end

    def announce_creation
      PlatformCore::EventBus.publish(
        "neighbor_help.request_created",
        request_id: id,
        actor_id: requester_id,
        requester_id: requester_id,
        target_path: target_path
      )
    end

    def announce_change
      PlatformCore::EventBus.publish(
        "neighbor_help.request_changed",
        request_id: id,
        actor_id: @event_actor_id,
        requester_id: requester_id,
        helper_id: helper_id,
        recipient_id: @event_recipient_id,
        status: display_status,
        change_kind: @event_change_kind,
        target_path: target_path
      )
    ensure
      @event_actor_id = @event_recipient_id = @event_change_kind = nil
    end

    def target_path
      "/neighbor_help/requests/#{id}"
    end
  end
end
