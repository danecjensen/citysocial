module Feed
  module UpdatePost
    module_function

    Result = Struct.new(:status, :post, :errors, keyword_init: true) do
      def success?
        status == :updated
      end
    end

    def call(post:, author_id:, attributes:, photos: [])
      unless owned_by?(post, author_id)
        return Result.new(status: :forbidden, post: post, errors: ["Only the author can edit this post."])
      end

      previous_url = post.url
      post.assign_attributes(normalize(attributes))
      post.photos.attach(Array(photos).compact_blank)
      return Result.new(status: :invalid, post: post, errors: post.errors.full_messages) unless post.save

      if post.url != previous_url
        clear_preview(post)
        Feed::LinkPreview.enrich(post) if post.url.present?
      end

      PlatformCore::EventBus.publish("feed.post_updated", post_id: post.id, author_id: post.author_id, kind: post.kind)
      Result.new(status: :updated, post: post, errors: [])
    end

    def owned_by?(post, author_id)
      post.author_id.present? && post.author_id == author_id
    end
    private_class_method :owned_by?

    def normalize(attributes)
      attributes.to_h.symbolize_keys.slice(:title, :body, :url, :target_path).transform_values do |value|
        value.to_s.strip.presence
      end
    end
    private_class_method :normalize

    def clear_preview(post)
      post.preview_image.purge if post.preview_image.attached?
      post.update_columns(preview_title: nil, preview_description: nil, preview_site_name: nil)
    end
    private_class_method :clear_preview
  end
end
