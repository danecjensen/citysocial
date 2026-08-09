module PlatformCore
  # Public, module-neutral search registry. Product modules register opaque
  # callables; the kernel validates and groups their plain result values without
  # naming or loading sibling constants.
  module Search
    module_function

    MAX_QUERY_LENGTH = 100
    DEFAULT_LIMIT = 6
    MAX_LIMIT = 12

    Result = Data.define(:title, :subtitle, :path, :type)
    Provider = Data.define(:key, :label, :module_key, :types, :callable, :more_path)
    Group = Data.define(:key, :label, :types, :results, :more_path, :disabled, :unavailable)
    Response = Data.define(:query, :selected_type, :groups) do
      def blank?
        query.blank?
      end

      def any_results?
        groups.any? { |group| group.results.any? }
      end
    end

    class InvalidResult < StandardError; end

    def register(key:, label:, module_key:, types:, callable:, more_path: nil)
      provider = Provider.new(
        key: key.to_s.freeze,
        label: label.to_s.freeze,
        module_key: module_key.to_s.freeze,
        types: Array(types).map { |type| type.to_s.freeze }.uniq.freeze,
        callable: callable,
        more_path: more_path
      )
      registry[provider.key] = provider
      provider
    end

    def unregister(key)
      registry.delete(key.to_s)
    end

    def call(query:, type: nil, limit: DEFAULT_LIMIT)
      normalized_query = query.to_s.strip.first(MAX_QUERY_LENGTH)
      selected_type = normalized_type(type)
      result_limit = limit.to_i.clamp(1, MAX_LIMIT)
      groups = selected_providers(selected_type).map do |provider|
        build_group(provider, normalized_query, result_limit)
      end

      Response.new(query: normalized_query.freeze, selected_type: selected_type&.freeze, groups: groups.freeze)
    end

    def types
      registry.values.flat_map(&:types).uniq.freeze
    end

    def type_options
      registry.values.flat_map do |provider|
        provider.types.map { |type| [type.titleize, type] }
      end.uniq.freeze
    end

    def canonical_internal_path?(path)
      value = path.to_s
      value.start_with?("/") && !value.start_with?("//") && !value.match?(/[\\\u0000-\u001f\u007f]/)
    end

    def registry
      @registry ||= {}
    end
    private_class_method :registry

    def normalized_type(type)
      requested = type.to_s.strip
      types.include?(requested) ? requested : nil
    end
    private_class_method :normalized_type

    def selected_providers(selected_type)
      providers = registry.values
      return providers unless selected_type

      providers.select { |provider| provider.types.include?(selected_type) }
    end
    private_class_method :selected_providers

    def build_group(provider, query, limit)
      disabled = !PlatformCore::Modules.enabled?(provider.module_key)
      results = if query.blank? || disabled
                  []
                else
                  validated_results(provider, query, limit)
                end
      more_path = query.blank? || disabled ? nil : resolved_more_path(provider, query)

      Group.new(
        key: provider.key,
        label: provider.label,
        types: provider.types,
        results: results.freeze,
        more_path: more_path&.freeze,
        disabled: disabled,
        unavailable: false
      )
    rescue StandardError => e
      Rails.logger.error("Search provider #{provider.key} failed: #{e.class}")
      Group.new(
        key: provider.key,
        label: provider.label,
        types: provider.types,
        results: [].freeze,
        more_path: nil,
        disabled: false,
        unavailable: true
      )
    end
    private_class_method :build_group

    def validated_results(provider, query, limit)
      Array(provider.callable.call(query: query, limit: limit)).first(limit).map do |result|
        unless result.is_a?(Result) && provider.types.include?(result.type.to_s) &&
               canonical_internal_path?(result.path)
          raise InvalidResult, "provider returned an invalid result"
        end

        Result.new(
          title: result.title.to_s.freeze,
          subtitle: result.subtitle.to_s.freeze,
          path: result.path.to_s.freeze,
          type: result.type.to_s.freeze
        )
      end
    end
    private_class_method :validated_results

    def resolved_more_path(provider, query)
      return unless provider.more_path

      path = provider.more_path.call(query).to_s
      raise InvalidResult, "provider returned an invalid more-results path" unless canonical_internal_path?(path)

      path
    end
    private_class_method :resolved_more_path
  end
end
