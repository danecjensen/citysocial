module PlatformCore
  module Ui
    # Renders a resident avatar with a consistent initial fallback. Pass alt: ""
    # when a nearby visible handle already identifies the resident.
    class AvatarComponent < ViewComponent::Base
      SIZES = {
        sm: "h-8 w-8 text-xs",
        md: "h-10 w-10 text-sm",
        lg: "h-16 w-16 text-xl",
        xl: "h-24 w-24 text-3xl"
      }.freeze

      BASE = "inline-flex shrink-0 items-center justify-center rounded-full border border-line " \
             "bg-brand-100 font-display font-black text-brand-800".freeze

      def initialize(user:, size: :md, alt: nil)
        @user = user
        @size = SIZES.fetch(size)
        @alt = alt.nil? ? "#{user.display_name_or_handle}'s avatar" : alt
      end

      erb_template <<~ERB
        <% if renderable_avatar? %>
          <%= image_tag @user.avatar, class: "\#{classes} object-cover", alt: @alt %>
        <% else %>
          <%= tag.span @user.avatar_initial, class: classes, role: (@alt.present? ? "img" : nil),
                                              "aria-label": @alt.presence,
                                              "aria-hidden": (@alt.blank? ? "true" : nil) %>
        <% end %>
      ERB

      private

      def renderable_avatar?
        @user.avatar.attached? && @user.avatar.blob.persisted?
      end

      def classes
        [BASE, @size].join(" ")
      end
    end
  end
end
