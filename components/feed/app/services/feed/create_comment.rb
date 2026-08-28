module Feed
  module CreateComment
    module_function

    Result = Struct.new(:status, :comment, :errors, keyword_init: true) do
      def success?
        status == :created
      end
    end

    def call(post:, author_id:, body:)
      comment = post.comments.build(author_id: author_id, body: body.to_s.strip)
      return Result.new(status: :invalid, comment: comment, errors: comment.errors.full_messages) unless comment.save

      PlatformCore::EventBus.publish(
        "feed.comment_created",
        comment_id: comment.id,
        post_id: post.id,
        author_id: author_id,
        post_author_id: post.author_id
      )
      Result.new(status: :created, comment: comment, errors: [])
    end
  end
end
