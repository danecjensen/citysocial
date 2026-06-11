module PlatformCore
  module Ui
    # Wraps a form-builder input with a styled label and inline errors.
    #   <%= render PlatformCore::Ui::FormFieldComponent.new(form: f, attribute: :email, type: :email_field) %>
    class FormFieldComponent < ViewComponent::Base
      INPUT_TYPES = %i[text_field email_field password_field number_field text_area].freeze

      INPUT_CLASSES = "w-full rounded-md border border-line bg-surface px-3 py-2 text-sm text-ink " \
                      "placeholder:text-ink-faint focus:border-brand-500 focus:outline-none " \
                      "focus:ring-2 focus:ring-brand-200".freeze

      def initialize(form:, attribute:, type: :text_field, label: nil, hint: nil, **input_options)
        raise ArgumentError, "unsupported input type #{type}" unless INPUT_TYPES.include?(type)

        @form = form
        @attribute = attribute
        @type = type
        @label = label
        @hint = hint
        @input_options = input_options
      end

      erb_template <<~ERB
        <div class="mb-4">
          <%= @form.label @attribute, @label, class: "mb-1 block text-sm font-bold text-ink" %>
          <%= @form.public_send(@type, @attribute, **@input_options, class: input_classes) %>
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
