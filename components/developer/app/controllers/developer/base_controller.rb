module Developer
  class BaseController < PlatformCore::BaseController
    EXCLUDED_FORM_ATTRIBUTES = %w[id created_at updated_at password_digest].freeze
    JSON_TYPES = %i[json jsonb].freeze
    NUMERIC_TYPES = %i[integer bigint decimal float].freeze

    before_action :require_login
    before_action :require_admin

    helper_method :developer_models, :editable_columns, :form_field_options,
                  :model_identifier, :password_attributes

    private

    def developer_models
      Developer::ModelRegistry.all
    end

    def find_model(identifier)
      Developer::ModelRegistry.find(identifier)
    end

    def model_identifier(model)
      Developer::ModelRegistry.identifier_for(model)
    end

    def editable_columns
      @model.columns.reject { |column| EXCLUDED_FORM_ATTRIBUTES.include?(column.name) }
    end

    def editable_attribute_names(record)
      editable_columns.map(&:name) + password_attributes(record)
    end

    def password_attributes(record = @record)
      return [] unless record.respond_to?(:password=)

      %w[password password_confirmation]
    end

    def form_field_options(column, record = @record)
      base = { label: column.name, hint: column_hint(column) }

      if @model.defined_enums.key?(column.name)
        enum_options(column, record).merge(base)
      elsif column.type == :boolean
        boolean_options(column, record).merge(base)
      elsif column.type == :text || JSON_TYPES.include?(column.type)
        text_area_options(column, record).merge(base)
      elsif NUMERIC_TYPES.include?(column.type)
        number_options(column).merge(base)
      else
        text_options(column, record).merge(base)
      end
    end

    def enum_options(column, record)
      choices = @model.defined_enums.fetch(column.name).keys.map { |value| [value.humanize, value] }
      { type: :select, collection: choices, include_blank: column.null, selected: record[column.name] }
    end

    def boolean_options(column, record)
      choices = [["True", true], ["False", false]]
      { type: :select, collection: choices, include_blank: column.null, selected: record[column.name] }
    end

    def text_area_options(column, record)
      options = { type: :text_area, rows: column.type == :text ? 5 : 8 }
      return options unless JSON_TYPES.include?(column.type) && record[column.name].present?

      options.merge(value: JSON.pretty_generate(record[column.name]))
    end

    def number_options(column)
      step = %i[decimal float].include?(column.type) ? "any" : 1
      { type: :number_field, step: step }
    end

    def text_options(column, record)
      value = formatted_form_value(record[column.name])
      value.nil? ? {} : { value: value }
    end

    def formatted_form_value(value)
      return value.iso8601 if value.respond_to?(:iso8601)

      value
    end

    def column_hint(column)
      nullability = column.null ? "nullable" : "required by database"
      "#{column.sql_type} · #{nullability}"
    end
  end
end
