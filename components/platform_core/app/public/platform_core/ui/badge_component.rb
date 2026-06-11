module PlatformCore
  module Ui
    class BadgeComponent < ViewComponent::Base
      VARIANTS = {
        neutral: "bg-sunken text-ink-muted",
        brand: "bg-brand-100 text-brand-800",
        agave: "bg-agave-100 text-agave-700",
        success: "bg-success-soft text-success",
        danger: "bg-danger-soft text-danger"
      }.freeze

      def initialize(variant: :neutral)
        @variant = VARIANTS.fetch(variant)
      end

      erb_template <<~ERB
        <span class="inline-flex items-center rounded-xs px-2 py-0.5 text-xs font-bold uppercase tracking-wider <%= @variant %>"><%= content %></span>
      ERB
    end
  end
end
