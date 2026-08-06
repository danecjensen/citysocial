module Marketplace
  class Listing < ApplicationRecord
    CATEGORIES = %w[
      housing_rent housing_sale
      jobs_fulltime jobs_parttime jobs_gigs
      for_sale_electronics for_sale_furniture for_sale_clothing for_sale_vehicles for_sale_other
      services_professional services_home services_personal
      free_stuff wanted
    ].freeze

    CONDITIONS = %w[new like_new good fair poor].freeze

    # A listing may be resurfaced (bumped back to the top of `recent` and given a
    # fresh 30-day expiry) only after it has sat for this long since it was last
    # created or renewed — `created_at` doubles as the cooldown clock, so no new
    # column is needed.
    RENEW_COOLDOWN = 48.hours

    enum :status, { active: 0, sold: 1, expired: 2 }

    has_many_attached :photos

    validates :title, presence: true, length: { minimum: 5, maximum: 200 }
    validates :description, length: { maximum: 10_000 }, allow_blank: true
    validates :category, presence: true, inclusion: { in: CATEGORIES }
    validates :condition, inclusion: { in: CONDITIONS }, allow_blank: true
    validates :price_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

    before_validation :set_slug, on: :create
    before_create :set_expiration
    after_create_commit :announce_creation

    scope :active_listings, -> { where(status: :active).where("expires_at IS NULL OR expires_at > ?", Time.current) }
    scope :by_category, ->(cat) { where(category: cat) }
    scope :recent, -> { order(created_at: :desc) }
    scope :by_price_asc, -> { order(Arel.sql("price_cents IS NULL, price_cents ASC")) }
    scope :by_price_desc, -> { order(Arel.sql("price_cents DESC NULLS LAST")) }

    # Simple case-insensitive keyword search over title + description. No
    # PgSearch dependency — the module stays free of extra gems.
    scope :search, lambda { |query|
      q = "%#{sanitize_sql_like(query.to_s.strip)}%"
      where("title ILIKE :q OR description ILIKE :q", q: q)
    }

    def to_param
      slug
    end

    def author
      PlatformCore::Graph.user(author_id)
    end

    def price
      return nil if price_cents.nil?

      price_cents / 100.0
    end

    def price=(value)
      self.price_cents = value.blank? ? nil : (value.to_f * 100).round
    end

    def price_display
      return "Free" if price_cents.nil? || price_cents.zero?

      "$#{format('%.2f', price).sub(/\.00$/, '')}"
    end

    def category_display
      category.to_s.titleize
    end

    def increment_views!
      increment!(:views_count)
    end

    def mark_sold!
      update!(status: :sold)
      PlatformCore::EventBus.publish("marketplace.listing_sold", listing_id: id, author_id: author_id)
    end

    # True when the owner may renew: the listing is not sold and the cooldown
    # since its last create/renew has elapsed.
    def renewable?
      !sold? && created_at.present? && created_at <= RENEW_COOLDOWN.ago
    end

    # Resurface a stale listing: reset `created_at` so it returns to the top of
    # `recent` order, and push `expires_at` out 30 days. Rewriting `created_at`
    # is intentional — the "Posted … ago" line moves too, matching how bump/renew
    # works on comparable classifieds. Returns false (a no-op) when not renewable.
    def renew!
      return false unless renewable?

      update!(created_at: Time.current, expires_at: 30.days.from_now)
    end

    private

    def set_slug
      base = title.to_s.parameterize
      candidate = base
      suffix = 1
      while self.class.exists?(slug: candidate)
        suffix += 1
        candidate = "#{base}-#{suffix}"
      end
      self.slug = candidate
    end

    def set_expiration
      self.expires_at ||= 30.days.from_now
    end

    def announce_creation
      PlatformCore::EventBus.publish("marketplace.listing_created", listing_id: id, author_id: author_id)
    end
  end
end
