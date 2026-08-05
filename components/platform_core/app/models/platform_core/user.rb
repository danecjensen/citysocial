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
