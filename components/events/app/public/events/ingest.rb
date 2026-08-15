module Events
  # The canonical write path for one event. Transports supply an authenticated
  # producer source and its stable external ID; this command normalizes input,
  # updates changed repeats, skips exact retries, and preserves the module's
  # deterministic real-world fingerprint deduplication across producers.
  module Ingest
    module_function

    PERMITTED = %w[
      title description venue category url image_url starts_at ends_at price
      score confidence why ticket_urgency age_limit
    ].freeze

    Result = Struct.new(:status, :event, :errors, keyword_init: true) do
      def success?
        %i[created updated duplicate].include?(status)
      end
    end

    BatchResult = Struct.new(:created, :updated, :duplicates, :skipped, :errors, keyword_init: true) do
      def total_written
        created + updated
      end

      def to_h
        {
          created: created,
          updated: updated,
          duplicates: duplicates,
          skipped: skipped,
          errors: errors
        }
      end
    end

    def call(source:, payload:, external_id:)
      attrs = normalize(payload).merge(
        source: source.to_s.strip.downcase,
        external_id: external_id.to_s.strip
      )
      validation_errors = required_errors(attrs)
      return Result.new(status: :invalid, event: nil, errors: validation_errors) if validation_errors.any?

      by_identity = Events::Event.find_by(source: attrs[:source], external_id: attrs[:external_id])
      return persist_existing(by_identity, attrs) if by_identity

      fingerprint = Events::Event.fingerprint_for(attrs[:title], attrs[:venue], attrs[:starts_at])
      by_fingerprint = Events::Event.find_by(fingerprint: fingerprint)
      return merge_fingerprint_duplicate(by_fingerprint, attrs) if by_fingerprint

      persist_new(attrs)
    rescue ActiveRecord::RecordNotUnique
      duplicate = Events::Event.find_by(source: attrs[:source], external_id: attrs[:external_id]) ||
                  Events::Event.find_by(fingerprint: fingerprint)
      Result.new(status: :duplicate, event: duplicate, errors: [])
    end

    # Batch transport for rake feeds. Every row still passes through .call;
    # this method only derives legacy feed identities and aggregates results.
    def call_many(records, source: nil)
      batch = BatchResult.new(created: 0, updated: 0, duplicates: 0, skipped: 0, errors: [])

      Array(records).each_with_index do |raw, index|
        identity = identity_for(raw, default_source: source)
        result = call(source: identity[:source], external_id: identity[:external_id], payload: raw)
        collect(batch, result, index)
      end

      announce_batch(batch)
      batch
    end

    def persist_new(attrs)
      event = Events::Event.new(attrs.merge(last_seen_at: Time.current))
      return invalid(event) unless event.save

      announce_event(event, :created)
      Result.new(status: :created, event: event, errors: [])
    end
    private_class_method :persist_new

    def persist_existing(event, attrs)
      if unchanged?(event, attrs)
        event.update_column(:last_seen_at, Time.current)
        return Result.new(status: :duplicate, event: event, errors: [])
      end

      event.assign_attributes(attrs.merge(last_seen_at: Time.current))
      return invalid(event) unless event.save

      announce_event(event, :updated)
      Result.new(status: :updated, event: event, errors: [])
    end
    private_class_method :persist_existing

    # If another producer already discovered the same real-world event, retain
    # the first producer identity. The fingerprint remains the cross-source
    # canonical key and the retry is safely reported as a duplicate.
    def merge_fingerprint_duplicate(event, attrs)
      return persist_existing(event, attrs) if event.external_id.blank?

      event.update_column(:last_seen_at, Time.current)
      Result.new(status: :duplicate, event: event, errors: [])
    end
    private_class_method :merge_fingerprint_duplicate

    def invalid(event)
      Result.new(status: :invalid, event: event, errors: event.errors.full_messages)
    end
    private_class_method :invalid

    def normalize(raw)
      hash = raw.to_h.transform_keys(&:to_s)
      attrs = PERMITTED.each_with_object({}) do |key, permitted|
        permitted[key.to_sym] = hash[key] if hash.key?(key)
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
    private_class_method :normalize

    def parse_time(value)
      return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end
    private_class_method :parse_time

    def clamp_category(value)
      key = value.to_s.strip.downcase.gsub(/[^a-z]+/, "_")
      Events::Event::CATEGORIES.include?(key) ? key : "other"
    end
    private_class_method :clamp_category

    def required_errors(attrs)
      errors = []
      errors << "source can't be blank" if attrs[:source].blank?
      errors << "external ID can't be blank" if attrs[:external_id].blank?
      errors << "title can't be blank" if attrs[:title].blank?
      errors << "starts at can't be blank" if attrs[:starts_at].blank?
      errors
    end
    private_class_method :required_errors

    def unchanged?(event, attrs)
      attrs.all? do |attribute, value|
        current = event.public_send(attribute)
        current == value || (current.blank? && value.blank?)
      end
    end
    private_class_method :unchanged?

    def identity_for(raw, default_source:)
      hash = raw.to_h.transform_keys(&:to_s)
      record_source = default_source.presence || hash["source"].presence || "events-feed"
      external_id = hash["external_id"].presence || hash["url"].presence
      external_id ||= Events::Event.fingerprint_for(hash["title"], hash["venue"], hash["starts_at"])
      { source: record_source, external_id: external_id }
    end
    private_class_method :identity_for

    def collect(batch, result, index)
      case result.status
      when :created then batch.created += 1
      when :updated then batch.updated += 1
      when :duplicate then batch.duplicates += 1
      else
        batch.skipped += 1
        batch.errors << { index: index, messages: result.errors }
      end
    end
    private_class_method :collect

    def announce_event(event, status)
      PlatformCore::EventBus.publish(
        "events.event_ingested",
        event_id: event.id,
        source: event.source,
        external_id: event.external_id,
        status: status,
        target_path: "/events/e/#{event.id}"
      )
    end
    private_class_method :announce_event

    def announce_batch(batch)
      return if batch.total_written.zero?

      PlatformCore::EventBus.publish(
        "events.events_ingested",
        created: batch.created,
        updated: batch.updated
      )
    end
    private_class_method :announce_batch
  end
end
