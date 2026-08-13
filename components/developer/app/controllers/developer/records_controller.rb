require "csv"

module Developer
  class RecordsController < BaseController
    PER_PAGE = 100

    before_action :load_model
    before_action :load_record, only: %i[show edit update destroy]

    helper_method :display_value, :record_identifier, :sort_heading

    def index
      @columns = @model.column_names
      @sort_column, @sort_direction = resolve_sort
      scope = @model.order(@sort_column => @sort_direction)

      respond_to do |format|
        format.html { load_page(scope) }
        format.csv { send_csv(scope) }
      end
    end

    def show; end

    def new
      @record = @model.new
    end

    def edit; end

    def create
      @record = @model.new
      @record.assign_attributes(record_attributes)

      if parameters_valid? && @record.save
        redirect_to record_path(model: model_identifier(@model), id: record_identifier(@record)),
                    notice: "#{@model.name} ##{record_identifier(@record)} created."
      else
        add_parameter_errors
        render :new, status: :unprocessable_content
      end
    end

    def update
      @record.assign_attributes(record_attributes)

      if parameters_valid? && @record.save
        redirect_to record_path(model: model_identifier(@model), id: record_identifier(@record)),
                    notice: "#{@model.name} ##{record_identifier(@record)} updated."
      else
        add_parameter_errors
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @record.destroy
        redirect_to records_path(model: model_identifier(@model)),
                    notice: "#{@model.name} ##{record_identifier(@record)} deleted."
      else
        redirect_to record_path(model: model_identifier(@model), id: record_identifier(@record)),
                    alert: @record.errors.full_messages.to_sentence.presence || "The record could not be deleted."
      end
    rescue ActiveRecord::InvalidForeignKey, ActiveRecord::DeleteRestrictionError => e
      redirect_to record_path(model: model_identifier(@model), id: record_identifier(@record)),
                  alert: "The record could not be deleted: #{e.message}"
    end

    private

    def load_model
      @model = find_model(params[:model])
      return if @model

      redirect_to root_path, alert: "Unknown model: #{params[:model].inspect}"
    end

    def load_record
      @record = @model.find(params[:id])
    end

    def load_page(scope)
      @total_count = scope.count
      @total_pages = [(@total_count.to_f / PER_PAGE).ceil, 1].max
      @page = params[:page].to_i.clamp(1, @total_pages)
      @records = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE).to_a
    end

    def send_csv(scope)
      send_data build_csv(scope),
                filename: "#{model_identifier(@model)}-#{Time.current.strftime('%Y%m%d-%H%M%S')}.csv",
                type: "text/csv; charset=utf-8"
    end

    def build_csv(scope)
      columns = @model.column_names

      CSV.generate do |csv|
        csv << columns
        scope.each do |record|
          csv << columns.map { |column| csv_value(record[column]) }
        end
      end
    end

    def csv_value(value)
      case value
      when Hash, Array
        JSON.generate(value)
      when Time, Date, DateTime, ActiveSupport::TimeWithZone
        value.iso8601
      else
        value
      end
    end

    def resolve_sort
      columns = @model.column_names
      default_column = @model.primary_key.presence_in(columns) || columns.first
      column = params[:sort].presence_in(columns) || default_column
      direction = params[:dir] == "asc" ? :asc : :desc
      [column, direction]
    end

    def record_attributes
      key = @model.model_name.param_key
      submitted = params[key] || ActionController::Parameters.new
      permitted = submitted.permit(*editable_attribute_names(@record)).to_h
      discard_blank_password(permitted)
      parse_json_attributes(permitted)
      permitted
    end

    def discard_blank_password(attributes)
      return unless @record.persisted?
      return unless password_attributes(@record).all? { |attribute| attributes[attribute].blank? }

      password_attributes(@record).each { |attribute| attributes.delete(attribute) }
    end

    def parse_json_attributes(attributes)
      editable_columns.select { |column| JSON_TYPES.include?(column.type) }.each do |column|
        next unless attributes.key?(column.name)

        attributes[column.name] = parse_json_value(attributes[column.name], column)
      end
    end

    def parse_json_value(value, column)
      return nil if value.blank? && column.null

      JSON.parse(value)
    rescue JSON::ParserError
      parameter_errors[column.name] = "must be valid JSON"
      value
    end

    def parameters_valid?
      parameter_errors.empty?
    end

    def add_parameter_errors
      parameter_errors.each { |attribute, message| @record.errors.add(attribute, message) }
    end

    def parameter_errors
      @parameter_errors ||= {}
    end

    def record_identifier(record)
      record.public_send(@model.primary_key)
    end

    def display_value(record, column)
      value = record[column]
      return "NULL" if value.nil?
      return JSON.pretty_generate(value) if value.is_a?(Hash) || value.is_a?(Array)
      return value.iso8601 if value.respond_to?(:iso8601)

      value.to_s
    end

    def sort_heading(column)
      active = column == @sort_column
      direction = active && @sort_direction == :asc ? "desc" : "asc"
      indicator = sort_indicator(active)

      view_context.link_to(
        "#{column}#{indicator}",
        records_path(model: model_identifier(@model), sort: column, dir: direction),
        class: "whitespace-nowrap font-mono text-xs font-bold text-ink-muted hover:text-brand-700"
      )
    end

    def sort_indicator(active)
      return "" unless active

      @sort_direction == :asc ? " ▲" : " ▼"
    end
  end
end
