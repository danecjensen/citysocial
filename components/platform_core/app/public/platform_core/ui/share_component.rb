module PlatformCore
  module Ui
    # Reusable progressive-enhancement control for public CitySocial pages.
    # Copy link is permanent; the browser-native action is revealed only when
    # navigator.share is available.
    class ShareComponent < ViewComponent::Base
      def initialize(title:, url:)
        @title = title
        @url = url
      end

      erb_template <<~ERB
        <div class="rounded-lg border border-line bg-sunken/50 p-4"
             data-controller="share"
             data-share-title-value="<%= @title %>"
             data-share-url-value="<%= @url %>">
          <p class="mb-3 font-mono text-xs uppercase tracking-wide text-ink-muted">Share</p>
          <div class="flex flex-wrap gap-2">
            <%= render PlatformCore::Ui::ButtonComponent.new(
              variant: :secondary,
              type: :button,
              data: { action: "share#copy" }
            ) do %>🔗 Copy link<% end %>
            <span data-share-target="native" hidden>
              <%= render PlatformCore::Ui::ButtonComponent.new(
                variant: :secondary,
                type: :button,
                data: { action: "share#native" }
              ) do %>↗ Share<% end %>
            </span>
          </div>
          <p class="mt-2 min-h-5 text-sm text-ink-muted"
             data-share-target="status"
             role="status"
             aria-live="polite"></p>
        </div>
      ERB
    end
  end
end
