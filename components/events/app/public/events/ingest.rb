module Events
  # The one supported way structured event data enters the module. Callers hand
  # over plain hashes (from a routine's JSON feed, a rake task, a spec) and this
  # deterministically upserts them: it computes each event's fingerprint in Ruby
  # and does find_or_initialize_by(fingerprint:), so re-ingesting the same feed
  # is idempotent and dedup NEVER depends on an LLM.
  #
  #   Events::Ingest.call([{ "title" => "...", "venue" => "...",
  #                          "starts_at" => "2026-08-06T20:00:00-05:00", ... }])
  #   # => { created: 3, updated: 1, skipped: 0, errors: [] }
  #
  # This is the module's public surface for siblings and the host — Packwerk
  # privacy allows exactly this file to be called from outside the module.
  module Ingest
    module_function

    PERMITTED = %w[
      title description venue category url image_url starts_at ends_at price
      score confidence source
    ].freeze

    Result = Struct.new(:created, :updated, :skipped, :errors, keyword_init: true) do
      def total_written
        created + updated
      end

      def to_h
        { created: created, updated: updated, skipped: skipped, errors: errors }
      end
    end

    # `records` is an Array of Hashes (string or symbol keys). Returns a Result.
    def call(records)
      result = Result.new(created: 0, updated: 0, skipped: 0, errors: [])

      Array(records).each_with_index do |raw, index|
        attrs = normalize(raw)

        if attrs[:title].blank? || attrs[:starts_at].blank?
          result.skipped += 1
          next
        end

        upsert_one(attrs, result, index)
      end

      announce(result)
      result
    end

    # --- internals ---------------------------------------------------------

    def upsert_one(attrs, result, index)
      fingerprint = Events::Event.fingerprint_for(attrs[:title], attrs[:venue], attrs[:starts_at])
      event = Events::Event.find_or_initialize_by(fingerprint: fingerprint)
      was_new = event.new_record?

      event.assign_attributes(attrs.merge(last_seen_at: Time.current))

      if event.save
        was_new ? result.created += 1 : result.updated += 1
      else
        result.errors << { index: index, title: attrs[:title], messages: event.errors.full_messages }
      end
    end

    # Coerce an arbitrary hash into clean, typed attributes. Unknown keys are
    # dropped; times are parsed to real Time objects; category is clamped.
    def normalize(raw)
      h = raw.to_h.transform_keys(&:to_s)

      attrs = PERMITTED.each_with_object({}) do |key, acc|
        acc[key.to_sym] = h[key] if h.key?(key)
      end

      attrs[:title] = attrs[:title].to_s.strip if attrs.key?(:title)
      attrs[:venue] = attrs[:venue].to_s.strip if attrs.key?(:venue)
      attrs[:starts_at] = parse_time(attrs[:starts_at]) if attrs.key?(:starts_at)
      attrs[:ends_at] = parse_time(attrs[:ends_at]) if attrs.key?(:ends_at)
      attrs[:category] = clamp_category(attrs[:category]) if attrs.key?(:category)
      attrs[:score] = attrs[:score].to_f if attrs.key?(:score)
      attrs[:confidence] = attrs[:confidence].to_f if attrs.key?(:confidence)
      attrs
    end

    def parse_time(value)
      return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def clamp_category(value)
      key = value.to_s.strip.downcase.gsub(/[^a-z]+/, "_")
      Events::Event::CATEGORIES.include?(key) ? key : "other"
    end

    def announce(result)
      return if result.total_written.zero?

      PlatformCore::EventBus.publish(
        "events.events_ingested",
        created: result.created,
        updated: result.updated
      )
    end
  end
end
