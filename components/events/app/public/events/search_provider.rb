module Events
  # Public adapter that exposes future public events to the kernel's search
  # contract while keeping ranking and lifecycle rules inside Events.
  module SearchProvider
    module_function

    def call(query:, limit:)
      normalized = query.to_s.strip.downcase
      rank_sql = Events::Event.sanitize_sql_array(
        [
          "CASE WHEN LOWER(BTRIM(title)) = :exact THEN 0 " \
          "WHEN LOWER(BTRIM(title)) LIKE :prefix THEN 1 ELSE 2 END",
          { exact: normalized, prefix: "#{Events::Event.sanitize_sql_like(normalized)}%" }
        ]
      )

      Events::Event.where(starts_at: Time.current..).search(query)
                   .order(Arel.sql(rank_sql), starts_at: :asc, id: :asc)
                   .limit(limit)
                   .map do |event|
        PlatformCore::Search::Result.new(
          title: event.title,
          subtitle: [event.when_display, event.venue, event.price_display].compact_blank.join(" · "),
          path: "/events/e/#{event.id}",
          type: "event"
        )
      end
    end

    def more_path(query)
      "/events/all?#{Rack::Utils.build_query(q: query)}"
    end
  end
end
