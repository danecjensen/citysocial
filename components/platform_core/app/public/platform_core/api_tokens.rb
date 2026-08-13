module PlatformCore
  # Public credential API for ingestion transports. Callers never receive the
  # private ApiToken model, and the plaintext bearer token is only returned by
  # .issue! at creation time.
  module ApiTokens
    module_function

    TOKEN_PREFIX = "cs_ingest_".freeze
    Credential = Struct.new(:id, :source, :user_id, keyword_init: true)
    IssuedToken = Struct.new(:id, :source, :user_id, :token, keyword_init: true)

    def issue!(source:, user_id:)
      secret = "#{TOKEN_PREFIX}#{SecureRandom.urlsafe_base64(32)}"
      record = PlatformCore::ApiToken.create!(
        source: source,
        user_id: user_id,
        token_digest: digest(secret)
      )

      IssuedToken.new(id: record.id, source: record.source, user_id: record.user_id, token: secret)
    end

    def authenticate(secret)
      return if secret.blank?

      record = PlatformCore::ApiToken.active.find_by(token_digest: digest(secret))
      return unless record

      record.update_column(:last_used_at, Time.current)
      Credential.new(id: record.id, source: record.source, user_id: record.user_id)
    end

    def revoke!(id)
      PlatformCore::ApiToken.find(id).update!(revoked_at: Time.current)
    end

    def digest(secret)
      Digest::SHA256.hexdigest(secret.to_s)
    end
    private_class_method :digest
  end
end
