module Feed
  module LinkPreview
    module_function

    def enrich(post)
      preview = Feed::FetchLinkPreview.call(post.url)
      post.update!(
        preview_title: clean(preview.title, 300),
        preview_description: clean(preview.description, 1_000),
        preview_site_name: clean(preview.site_name, 120)
      )
      attach_image(post, preview)
      post
    rescue StandardError => e
      Rails.logger.info("event=feed_link_preview_skipped post_id=#{post.id} error=#{e.class.name}")
      post
    end

    def attach_image(post, preview)
      return unless preview.image_io

      post.preview_image.attach(
        io: preview.image_io,
        filename: preview.image_filename,
        content_type: preview.image_content_type
      )
    end
    private_class_method :attach_image

    def clean(value, limit)
      value.to_s.squish.first(limit).presence
    end
    private_class_method :clean
  end
end
