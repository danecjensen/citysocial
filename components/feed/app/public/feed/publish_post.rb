module Feed
  # The canonical write path for feed posts. Web forms, API controllers, jobs,
  # and scripts all delegate here so normalization, idempotency, and event
  # publication cannot drift between transports.
  module PublishPost
    module_function

    Result = Struct.new(:status, :post, :errors, keyword_init: true) do
      def success?
        %i[created duplicate].include?(status)
      end

      def to_h
        { status: status, post: post, errors: errors }
      end
    end

    def call(source:, author_id:, external_id: nil, title: nil, url: nil, body: nil, kind: nil, target_path: nil,
             photos: [], poll_options: [], enrich_link: true)
      attrs = normalize(
        source: source,
        author_id: author_id,
        external_id: external_id,
        title: title,
        url: url,
        body: body,
        kind: kind,
        target_path: target_path,
        photos: photos
      )

      if attrs[:external_id].present?
        duplicate = Feed::Post.find_by(source: attrs[:source], external_id: attrs[:external_id])
        return Result.new(status: :duplicate, post: duplicate, errors: []) if duplicate
      end

      post = Feed::Post.new(attrs)
      post.photos.attach(Array(photos).compact_blank)
      normalized_poll_options(poll_options).each_with_index do |label, index|
        post.public_send("#{Feed::Post::POLL_OPTION_ATTRIBUTES[index]}=", label)
        post.poll_options.build(label: label)
      end
      return Result.new(status: :invalid, post: post, errors: post.errors.full_messages) unless post.save

      Feed::LinkPreview.enrich(post) if enrich_link && post.url.present?

      PlatformCore::EventBus.publish(
        "feed.post_created",
        post_id: post.id,
        author_id: post.author_id,
        source: post.source
      )
      Result.new(status: :created, post: post, errors: [])
    rescue ActiveRecord::RecordNotUnique
      duplicate = Feed::Post.find_by!(source: attrs[:source], external_id: attrs[:external_id])
      Result.new(status: :duplicate, post: duplicate, errors: [])
    end

    def normalize(source:, author_id:, external_id:, title:, url:, body:, kind:, target_path:, photos:)
      normalized_url = url.to_s.strip.presence
      {
        source: source.to_s.strip.downcase,
        author_id: author_id,
        external_id: external_id.to_s.strip.presence,
        title: title.to_s.strip.presence,
        url: normalized_url,
        body: body.to_s.strip.presence,
        kind: normalized_kind(kind, normalized_url, photos: photos),
        target_path: target_path.to_s.strip.presence
      }
    end
    private_class_method :normalize

    def normalized_kind(kind, url, photos:)
      requested = kind.to_s.strip
      return requested if requested.present?
      return "link" if url.present?
      return "photo" if Array(photos).present?

      "text"
    end
    private_class_method :normalized_kind

    def normalized_poll_options(options)
      Array(options).map { |option| option.to_s.strip }.compact_blank.first(4)
    end
    private_class_method :normalized_poll_options
  end
end
