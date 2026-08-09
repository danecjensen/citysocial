module Marketplace
  # Public adapter from Marketplace's domain query to the kernel's plain search
  # result contract. Only active, unexpired inventory can leave this boundary.
  module SearchProvider
    module_function

    def call(query:, limit:)
      normalized = query.to_s.strip.downcase
      rank_sql = Marketplace::Listing.sanitize_sql_array(
        [
          "CASE WHEN LOWER(BTRIM(title)) = :exact THEN 0 " \
          "WHEN LOWER(BTRIM(title)) LIKE :prefix THEN 1 ELSE 2 END",
          { exact: normalized, prefix: "#{Marketplace::Listing.sanitize_sql_like(normalized)}%" }
        ]
      )

      Marketplace::Listing.active_listings.search(query)
                          .order(Arel.sql(rank_sql), created_at: :desc, id: :asc)
                          .limit(limit)
                          .map do |listing|
        PlatformCore::Search::Result.new(
          title: listing.title,
          subtitle: [listing.price_display, listing.category_display, listing.location].compact_blank.join(" · "),
          path: "/marketplace/#{listing.to_param}",
          type: "listing"
        )
      end
    end

    def more_path(query)
      "/marketplace?#{Rack::Utils.build_query(q: query)}"
    end
  end
end
