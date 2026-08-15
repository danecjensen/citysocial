module PlatformCore
  # The single source of identity. Modules reference users by id; they do not
  # define their own user tables.
  class User < ApplicationRecord
    AVATAR_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
    AVATAR_MAX_SIZE = 5.megabytes
    PUBLIC_PROFILE_FIELDS = %w[display_name neighborhood bio avatar].freeze

    has_secure_password
    has_one_attached :avatar

    has_many :outgoing_follows, class_name: "PlatformCore::Follow",
                                foreign_key: :follower_id, dependent: :destroy
    has_many :following, through: :outgoing_follows, source: :followed

    has_many :incoming_follows, class_name: "PlatformCore::Follow",
                                foreign_key: :followed_id, dependent: :destroy
    has_many :followers, through: :incoming_follows, source: :follower

    has_many :api_tokens, class_name: "PlatformCore::ApiToken", dependent: :destroy

    validates :handle, presence: true, uniqueness: true
    validates :email, presence: true, uniqueness: { case_sensitive: false },
                      format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :display_name, length: { maximum: 80 }
    validates :neighborhood, length: { maximum: 80 }
    validates :bio, length: { maximum: 500 }
    validate :acceptable_avatar

    normalizes :email, with: ->(email) { email.strip.downcase }
    normalizes :display_name, :neighborhood, :bio, with: ->(value) { value&.strip.presence }

    def display_name_or_handle
      display_name.presence || handle
    end

    def avatar_initial
      display_name_or_handle.first.upcase
    end

    # Stable across browser and server analytics. Never use mutable PII such as
    # email or handle as a PostHog distinct id.
    def posthog_distinct_id
      PlatformCore::Analytics.distinct_id(id)
    end

    # True when this account signs in through an OAuth provider (e.g. Google).
    def oauth?
      provider.present?
    end

    # Find or create the local account for an OmniAuth identity (Google today).
    # New OAuth users get a generated unique handle and a random password (they
    # sign in with the provider, not a password). An existing account with the
    # same email is linked to the OAuth identity so residents keep one profile.
    #
    # NOTE: linking trusts the provider's verified email. See docs/lessons.md
    # before adding a second provider or an email/password reset flow.
    def self.from_omniauth(auth)
      return if auth.blank?

      provider = auth["provider"].to_s
      uid = auth["uid"].to_s
      return if provider.blank? || uid.blank?

      identity = find_by(provider: provider, uid: uid)
      return identity if identity

      info = auth["info"] || {}
      email = info["email"].to_s.strip.downcase
      return if email.blank?

      if (existing = find_by(email: email))
        existing.update!(provider: provider, uid: uid)
        return existing
      end

      create_from_omniauth(provider, uid, email, info["name"].presence)
    end

    # Create a brand-new account for an OAuth identity with a generated handle
    # and an unguessable random password (kept only to satisfy has_secure_password).
    def self.create_from_omniauth(provider, uid, email, name)
      password = SecureRandom.hex(24)
      create!(
        provider: provider,
        uid: uid,
        email: email,
        handle: generate_handle(name || email.split("@").first),
        display_name: name,
        password: password,
        password_confirmation: password
      )
    end
    private_class_method :create_from_omniauth

    # Derive a unique, lowercased handle from a display name or email local part,
    # suffixing digits on collision (dane, dane1, dane2, ...).
    def self.generate_handle(seed)
      base = seed.to_s.downcase.gsub(/[^a-z0-9]/, "")[0, 20].presence || "resident"
      candidate = base
      suffix = 0
      while exists?(handle: candidate)
        suffix += 1
        candidate = "#{base}#{suffix}"
      end
      candidate
    end
    private_class_method :generate_handle

    private

    def acceptable_avatar
      return unless avatar.attached?

      unless avatar.blob.content_type.in?(AVATAR_CONTENT_TYPES)
        errors.add(:avatar, "must be a JPEG, PNG, or WebP image")
      end
      errors.add(:avatar, "must be smaller than 5 MB") if avatar.blob.byte_size > AVATAR_MAX_SIZE
    end
  end
end
