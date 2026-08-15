module PlatformCore
  module Ui
    # Wraps a form-builder input with a styled label and inline errors.
    #   <%= render PlatformCore::Ui::FormFieldComponent.new(form: f, attribute: :email, type: :email_field) %>
    #
    # For dropdowns, pass type: :select with a collection (and optionally
    # include_blank:/selected:) so selects get the same label, styling, and
    # inline error treatment instead of being hand-rolled per view:
    #   <%= render PlatformCore::Ui::FormFieldComponent.new(form: f, attribute: :category,
    #         type: :select, label: "Category", collection: [["Furniture", "furniture"]],
    #         include_blank: "Choose one") %>
    class FormFieldComponent < ViewComponent::Base
      INPUT_TYPES = %i[
        text_field email_field password_field number_field text_area file_field
        date_field time_field datetime_local_field
      ].freeze

      INPUT_CLASSES = "w-full rounded-md border border-line bg-surface px-3 py-2 text-sm text-ink " \
                      "placeholder:text-ink-faint focus:border-brand-500 focus:outline-none " \
                      "focus:ring-2 focus:ring-brand-200".freeze

      def initialize(form:, attribute:, type: :text_field, label: nil, hint: nil,
                     collection: nil, include_blank: nil, selected: nil, **input_options)
        raise ArgumentError, "unsupported input type #{type}" unless INPUT_TYPES.include?(type) || type == :select
        raise ArgumentError, "type: :select requires a collection" if type == :select && collection.nil?

        @form = form
        @attribute = attribute
        @type = type
        @label = label
        @hint = hint
        @collection = collection
        @include_blank = include_blank
        @selected = selected
        @input_options = input_options
      end

      erb_template <<~ERB
        <div class="mb-4">
          <%= @form.label @attribute, @label, class: "mb-1 block text-sm font-bold text-ink" %>
          <% if @type == :select %>
            <%= @form.select @attribute, @collection, { include_blank: @include_blank, selected: @selected }, class: input_classes %>
          <% else %>
            <%= @form.public_send(@type, @attribute, **@input_options, class: input_classes) %>
          <% end %>
          <% if @hint %>
            <p class="mt-1 text-xs text-ink-faint"><%= @hint %></p>
          <% end %>
          <% errors.each do |message| %>
            <p class="mt-1 text-xs font-bold text-danger"><%= message %></p>
          <% end %>
        </div>
      ERB

      private

      def errors
        return [] unless @form.object.respond_to?(:errors)

        @form.object.errors.full_messages_for(@attribute)
      end

      def input_classes
        errors.any? ? "#{INPUT_CLASSES} border-danger" : INPUT_CLASSES
      end
    end
  end
end
