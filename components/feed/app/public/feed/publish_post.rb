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

    def call(source:, author_id:, external_id: nil, title: nil, url: nil, body: nil)
      attrs = normalize(
        source: source,
        author_id: author_id,
        external_id: external_id,
        title: title,
        url: url,
        body: body
      )

      if attrs[:external_id].present?
        duplicate = Feed::Post.find_by(source: attrs[:source], external_id: attrs[:external_id])
        return Result.new(status: :duplicate, post: duplicate, errors: []) if duplicate
      end

      post = Feed::Post.new(attrs)
      return Result.new(status: :invalid, post: post, errors: post.errors.full_messages) unless post.save

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

    def normalize(source:, author_id:, external_id:, title:, url:, body:)
      {
        source: source.to_s.strip.downcase,
        author_id: author_id,
        external_id: external_id.to_s.strip.presence,
        title: title.to_s.strip.presence,
        url: url.to_s.strip.presence,
        body: body.to_s.strip.presence
      }
    end
    private_class_method :normalize
  end
end
