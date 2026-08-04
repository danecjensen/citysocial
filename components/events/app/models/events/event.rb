module Events
  # A single real-world event in the Austin window. Rows are deduplicated by a
  # DETERMINISTIC fingerprint computed in Ruby (see .fingerprint_for) — never by
  # an LLM. The discovery routine may find the same event across several sources
  # or on several days; ingestion collapses those onto one row per
  # (title, venue, calendar-day).
  class Event < ApplicationRecord
    # Central Time is the canonical zone for "what day is this event on".
    TIME_ZONE = "America/Chicago".freeze

    # Ranking categories mirror the routine's interest profile. Anything the
    # routine can't classify lands in "other" rather than being rejected.
    CATEGORIES = %w[
      performing_arts experimental film music museums tech outdoors food other
    ].freeze

    CATEGORY_LABELS = {
      "performing_arts" => "Performing Arts",
      "experimental" => "Experimental & Immersive",
      "film" => "Film",
      "music" => "Live Music",
      "museums" => "Museums & Visual Art",
      "tech" => "Tech & Ideas",
      "outdoors" => "Outdoors",
      "food" => "Food & Drink",
      "other" => "Other"
    }.freeze

    CATEGORY_EMOJI = {
      "performing_arts" => "🎭",
      "experimental" => "🎪",
      "film" => "🎬",
      "music" => "🎸",
      "museums" => "🖼️",
      "tech" => "💡",
      "outdoors" => "🥾",
      "food" => "🍽️",
      "other" => "📍"
    }.freeze

    validates :title, presence: true
    validates :starts_at, presence: true
    validates :category, inclusion: { in: CATEGORIES }
    validates :fingerprint, presence: true, uniqueness: true

    before_validation :normalize_category
    before_validation :assign_fingerprint

    # --- Selection & ranking (deterministic, pure SQL) --------------------

    # Events happening from the start of today through `days` days out.
    scope :upcoming_within, lambda { |days = 7|
      start = Time.current.in_time_zone(TIME_ZONE).beginning_of_day
      finish = (start + days.days).end_of_day
      where(starts_at: start..finish)
    }

    # Highest taste-score first, then soonest. This is the entire "ranking" the
    # module does: order by a value produced upstream, break ties by time.
    scope :top_ranked, -> { order(score: :desc, starts_at: :asc, id: :asc) }

    scope :chronological, -> { order(starts_at: :asc, id: :asc) }

    scope :by_category, ->(cat) { where(category: cat) }

    # Case-insensitive keyword search over title, venue, and description. No
    # search gem — the module stays dependency-free, like Marketplace.
    scope :search, lambda { |query|
      q = "%#{sanitize_sql_like(query.to_s.strip)}%"
      where("title ILIKE :q OR venue ILIKE :q OR description ILIKE :q", q: q)
    }

    # The daily headline set: the `limit` best-scoring events in the week ahead.
    def self.weekly_top(limit = 10)
      upcoming_within(7).top_ranked.limit(limit)
    end

    # --- Deterministic dedup ----------------------------------------------

    # Public, testable, and pure: the same inputs always yield the same key.
    # Same title + venue + calendar day => same event, regardless of which
    # source reported it or how the time-of-day was rounded.
    def self.fingerprint_for(title, venue, starts_at)
      day = normalize_day(starts_at)
      basis = [normalize_text(title), normalize_text(venue), day].join("|")
      Digest::SHA256.hexdigest(basis)
    end

    def self.normalize_text(value)
      value.to_s.unicode_normalize(:nfkc).downcase.gsub(/[^a-z0-9]+/, " ").strip.squeeze(" ")
    end

    def self.normalize_day(starts_at)
      time = starts_at.is_a?(String) ? Time.zone.parse(starts_at) : starts_at
      return "" if time.nil?

      time.in_time_zone(TIME_ZONE).strftime("%Y-%m-%d")
    end

    # --- Display helpers ---------------------------------------------------

    def category_label
      CATEGORY_LABELS.fetch(category, "Other")
    end

    def category_emoji
      CATEGORY_EMOJI.fetch(category, "📍")
    end

    def price_display
      price.presence || "Free"
    end

    def local_start
      starts_at.in_time_zone(TIME_ZONE)
    end

    def when_display
      local_start.strftime("%a, %b %-d · %-l:%M %p")
    end

    def day_display
      local_start.strftime("%a, %b %-d")
    end

    private

    def normalize_category
      self.category = "other" unless CATEGORIES.include?(category)
    end

    def assign_fingerprint
      return if title.blank? || starts_at.blank?

      self.fingerprint = self.class.fingerprint_for(title, venue, starts_at)
    end
  end
end
