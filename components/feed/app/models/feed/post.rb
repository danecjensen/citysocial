module Feed
  class Post < ApplicationRecord
    validates :author_id, :source, presence: true
    validates :title, length: { maximum: 300 }
    validates :source, length: { maximum: 100 }
    validates :external_id, length: { maximum: 500 }, uniqueness: { scope: :source }, allow_nil: true
    validates :url, length: { maximum: 2_048 }
    validate :content_present
    validate :url_is_http

    # Reference the kernel's identity via its PUBLIC api, never the model.
    def author
      PlatformCore::Graph.user(author_id)
    end

    private

    def content_present
      return if title.present? || body.present? || url.present?

      errors.add(:base, "title, body, or URL must be present")
    end

    def url_is_http
      return if url.blank?

      uri = URI.parse(url)
      return if uri.is_a?(URI::HTTP) && uri.host.present?

      errors.add(:url, "must be an HTTP or HTTPS URL")
    rescue URI::InvalidURIError
      errors.add(:url, "must be an HTTP or HTTPS URL")
    end
  end
end
