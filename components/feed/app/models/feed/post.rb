module Feed
  class Post < ApplicationRecord
    KINDS = %w[text photo link poll event marketplace game activity].freeze
    IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
    IMAGE_MAX_SIZE = 10.megabytes
    PHOTO_LIMIT = 4
    POLL_OPTION_ATTRIBUTES = %i[poll_option_one poll_option_two poll_option_three poll_option_four].freeze

    attr_writer(*POLL_OPTION_ATTRIBUTES)

    has_many_attached :photos
    has_one_attached :preview_image

    has_many :comments, class_name: "Feed::Comment", dependent: :destroy, inverse_of: :post
    has_many :reactions, class_name: "Feed::Reaction", dependent: :destroy, inverse_of: :post
    has_many :saves, class_name: "Feed::Save", dependent: :destroy, inverse_of: :post
    has_many :poll_options, -> { order(:id) },
             class_name: "Feed::PollOption", dependent: :destroy, inverse_of: :post
    has_many :poll_votes, class_name: "Feed::PollVote", dependent: :destroy, inverse_of: :post

    validates :source, :kind, presence: true
    validates :author_id, presence: true, unless: :system_activity?
    validates :kind, inclusion: { in: KINDS }
    validates :title, length: { maximum: 300 }
    validates :body, length: { maximum: 40_000 }
    validates :source, length: { maximum: 100 }
    validates :external_id, length: { maximum: 500 }, uniqueness: { scope: :source }, allow_nil: true
    validates :url, length: { maximum: 2_048 }
    validates :target_path, length: { maximum: 1_000 }
    validate :content_present
    validate :url_is_http
    validate :target_path_is_internal
    validate :acceptable_photos
    validate :poll_has_enough_options
    validate :poll_has_question

    # Reference the kernel's identity via its PUBLIC api, never the model.
    def author
      PlatformCore::Graph.user(author_id)
    end

    def system_activity?
      source.to_s.start_with?("module:")
    end

    def kind_label
      return source.delete_prefix("module:").titleize if system_activity?

      kind.titleize
    end

    def reaction_for(user_id)
      reactions.detect { |reaction| reaction.user_id == user_id } if user_id
    end

    def saved_by?(user_id)
      user_id.present? && saves.any? { |save| save.user_id == user_id }
    end

    def poll_vote_for(user_id)
      poll_votes.detect { |vote| vote.user_id == user_id } if user_id
    end

    def poll_votes_total
      poll_options.sum(&:votes_count)
    end

    POLL_OPTION_ATTRIBUTES.each_with_index do |attribute, index|
      define_method(attribute) do
        instance_variable_get("@#{attribute}") || poll_options[index]&.label
      end
    end

    private

    def content_present
      return if title.present? || body.present? || url.present? || photos.attached?

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

    def target_path_is_internal
      return if target_path.blank?
      return if target_path.match?(%r{\A/(?!/)}) && !target_path.match?(/[\\\x00-\x1f\x7f]/)

      errors.add(:target_path, "must be a safe internal path")
    end

    def acceptable_photos
      errors.add(:photos, "can include at most #{PHOTO_LIMIT}") if photos.attachments.size > PHOTO_LIMIT

      photos.each do |photo|
        unless photo.blob.content_type.in?(IMAGE_CONTENT_TYPES)
          errors.add(:photos, "must be JPEG, PNG, WebP, or GIF images")
        end
        errors.add(:photos, "must each be smaller than 10 MB") if photo.blob.byte_size > IMAGE_MAX_SIZE
      end
    end

    def poll_has_enough_options
      return unless kind == "poll"

      count = poll_options.reject(&:marked_for_destruction?).count
      errors.add(:poll_options, "must include between 2 and 4 choices") unless count.between?(2, 4)
    end

    def poll_has_question
      errors.add(:title, "is required for a poll") if kind == "poll" && title.blank?
    end
  end
end
