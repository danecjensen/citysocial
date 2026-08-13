module Feed
  # How feed connects to the rest of the system. This is the reference example
  # every other module copies.
  module Events
    module_function

    def subscribe!
      # Feed reacts to nothing right now, but this is where it would. e.g. if a
      # `marketplace` module emitted "marketplace.listing_created", feed could
      # subscribe here to surface listings inline.
    end

    # Events feed PUBLISHES:
    #   - "feed.post_created" { post_id:, author_id:, source: }
    #     -> emitted by Feed::PublishPost after a successful create.
  end
end
