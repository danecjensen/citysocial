module PlatformCore
  # A revocable credential for one ingestion producer. Only a SHA-256 digest is
  # persisted; the bearer secret is returned once when the token is issued.
  class ApiToken < ApplicationRecord
    belongs_to :user, class_name: "PlatformCore::User"

    validates :source, presence: true, length: { maximum: 100 },
                       format: { with: /\A[a-z0-9][a-z0-9._-]*\z/ }
    validates :token_digest, presence: true, uniqueness: true

    normalizes :source, with: ->(source) { source.to_s.strip.downcase }

    scope :active, -> { where(revoked_at: nil) }
  end
end
