module PlatformCore
  # The single product-analytics boundary for the modular monolith. Feature
  # modules publish their normal domain events; this adapter turns those into
  # PII-minimized PostHog events with stable, shared user identity.
  module Analytics
    ACTOR_ID_KEYS = %i[
      user_id actor_id supporter_id resident_id author_id creator_id sender_id
      voter_id recipient_id host_id
    ].freeze
    SENSITIVE_PROPERTY_PATTERN = /
      (body|content|message|description|bio|email|password|secret|token|
       query|search|url|path|blob)
    /ix
    MAX_STRING_LENGTH = 200
    MAX_COLLECTION_LENGTH = 20

    module_function

    def enabled?
      Rails.configuration.x.posthog.enabled == true
    end

    def distinct_id(user_or_id)
      id = user_or_id.respond_to?(:id) ? user_or_id.id : user_or_id
      return if id.blank?

      value = id.to_s
      value.start_with?("user_") ? value : "user_#{value}"
    end

    def browser_config
      return unless enabled?

      {
        project_token: Rails.configuration.x.posthog.project_token,
        host: Rails.configuration.x.posthog.host
      }
    end

    def person_properties(user)
      {
        account_type: user.admin? ? "admin" : "resident",
        account_created_at: user.created_at&.iso8601
      }.compact
    end

    def identify(user)
      return false unless client_ready?

      PostHog.identify(
        distinct_id: distinct_id(user),
        properties: person_properties(user)
      )
      true
    rescue StandardError => e
      log_failure("identify", e)
      false
    end

    def capture(event_name, user_id: nil, properties: {})
      return false unless client_ready?

      clean_properties = sanitize_properties(properties).merge("analytics_source" => "server")
      options = {
        event: normalize_event_name(event_name),
        properties: clean_properties
      }

      if (actor_distinct_id = distinct_id(user_id))
        options[:distinct_id] = actor_distinct_id
      else
        clean_properties["$process_person_profile"] = false
      end

      PostHog.capture(options)
      true
    rescue StandardError => e
      log_failure(event_name, e)
      false
    end

    def capture_domain_event(event_name, payload)
      payload = payload.to_h.symbolize_keys
      actor_key = ACTOR_ID_KEYS.find { |key| payload[key].present? }
      schema_version = payload.delete(:event_schema_version) || 1
      properties = payload.except(actor_key).merge(
        domain_event: event_name.to_s,
        domain_module: event_name.to_s.split(".").first,
        event_schema_version: schema_version
      )

      capture(
        event_name.to_s.tr("._", " "),
        user_id: actor_key && payload[actor_key],
        properties: properties
      )
    end

    def sanitize_properties(properties)
      properties.to_h.each_with_object({}) do |(key, value), clean|
        key = key.to_s
        next if key.match?(SENSITIVE_PROPERTY_PATTERN)

        clean[key] = sanitize_value(value)
      end
    end
    private_class_method :sanitize_properties

    def sanitize_value(value)
      case value
      when String
        value.first(MAX_STRING_LENGTH)
      when Symbol
        value.to_s
      when Numeric, TrueClass, FalseClass, NilClass
        value
      when Time, Date, DateTime
        value.iso8601
      when Array
        value.first(MAX_COLLECTION_LENGTH).map { |item| sanitize_value(item) }
      when Hash
        sanitize_properties(value)
      end
    end
    private_class_method :sanitize_value

    def normalize_event_name(event_name)
      event_name.to_s.strip.downcase.gsub(/\s+/, " ")
    end
    private_class_method :normalize_event_name

    def client_ready?
      enabled? && defined?(PostHog) && PostHog.initialized?
    end
    private_class_method :client_ready?

    def log_failure(event_name, error)
      Rails.logger.warn(
        "event=posthog_capture_failed analytics_event=#{event_name.inspect} " \
        "error_class=#{error.class.name} error=#{error.message.inspect}"
      )
    end
    private_class_method :log_failure
  end
end
