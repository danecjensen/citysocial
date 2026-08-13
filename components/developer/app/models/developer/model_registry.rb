module Developer
  # Finds concrete application records without naming any sibling module. The
  # source-path check deliberately excludes framework-owned records such as
  # Active Storage blobs and Action Text rich text rows.
  module ModelRegistry
    module_function

    MODEL_PATH_PATTERN = %r{\A(?:app/models|components/[^/]+/app/models)/}
    IDENTIFIER_PATTERN = /\A[a-z0-9_]+\z/

    def all
      Rails.application.eager_load! unless Rails.application.config.eager_load

      ActiveRecord::Base.descendants
                        .select { |model| available_application_model?(model) }
                        .sort_by(&:name)
    end

    def find(identifier)
      all.find { |model| identifier_for(model) == identifier.to_s }
    end

    def identifier_for(model)
      model.table_name
    end

    def available_application_model?(model)
      return false if model.abstract_class? || model.name.blank?
      return false unless model.name.safe_constantize.equal?(model)
      return false unless application_source?(model)
      return false unless identifier_for(model).match?(IDENTIFIER_PATTERN)

      model.table_exists?
    rescue ActiveRecord::StatementInvalid
      false
    end
    private_class_method :available_application_model?

    def application_source?(model)
      source = Object.const_source_location(model.name)&.first
      return false unless source

      relative_source = Pathname.new(source).expand_path.relative_path_from(Rails.root).to_s
      relative_source.match?(MODEL_PATH_PATTERN)
    rescue ArgumentError
      false
    end
    private_class_method :application_source?
  end
end
