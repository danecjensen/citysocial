module PlatformCore
  module Ui
    # Renders an <a> when given href:, a button_to form when given href: +
    # method:, otherwise a plain <button>. Variant/size class maps are complete
    # literal strings on purpose: Tailwind's scanner purges anything it cannot
    # see verbatim.
    class ButtonComponent < ViewComponent::Base
      VARIANTS = {
        primary: "bg-brand-600 text-white hover:bg-brand-700 active:bg-brand-800",
        secondary: "bg-surface text-ink border border-line hover:border-brand-400 hover:text-brand-700",
        danger: "bg-danger text-white hover:bg-danger/90",
        ghost: "text-brand-700 hover:bg-brand-50"
      }.freeze

      SIZES = {
        sm: "px-3 py-1.5 text-sm gap-1",
        md: "px-4 py-2 text-sm gap-1.5",
        lg: "px-5 py-2.5 text-base gap-2"
      }.freeze

      BASE = "inline-flex items-center justify-center rounded-md font-bold tracking-wide " \
             "transition-colors cursor-pointer".freeze

      def initialize(variant: :primary, size: :md, href: nil, method: nil, params: nil, confirm: nil, type: :submit,
                     aria_label: nil, pressed: nil, target: nil, rel: nil)
        @variant = VARIANTS.fetch(variant)
        @size = SIZES.fetch(size)
        @href = href
        @method = method
        @params = params
        @confirm = confirm
        @type = type
        @aria_label = aria_label
        @pressed = pressed
        @target = target
        @rel = rel
      end

      erb_template <<~ERB
        <% if @href && @method %>
          <%= button_to @href, method: @method, params: @params, class: classes,
                        form_class: "inline-flex", "aria-label": @aria_label, "aria-pressed": @pressed,
                        data: ({ turbo_confirm: @confirm } if @confirm) do %><%= content %><% end %>
        <% elsif @href %>
          <%= link_to @href, class: classes, target: @target, rel: @rel,
                      "aria-label": @aria_label, "aria-pressed": @pressed do %><%= content %><% end %>
        <% else %>
          <%= content_tag :button, content, type: @type, class: classes, "aria-label": @aria_label, "aria-pressed": @pressed %>
        <% end %>
      ERB

      private

      def classes
        [BASE, @variant, @size].join(" ")
      end
    end
  end
end
