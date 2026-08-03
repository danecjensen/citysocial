module PlatformCore
  module Ui
    # Site footer. Brand blurb on the left; the caller supplies columns of links
    # via `with_column(title:)` slots so the footer reflects whatever modules are
    # enabled without this component knowing about them.
    class FooterComponent < ViewComponent::Base
      renders_many :columns, "ColumnComponent"

      erb_template <<~ERB
        <footer class="mt-16 border-t border-line bg-surface">
          <div class="mx-auto grid max-w-6xl grid-cols-2 gap-8 px-4 py-12 md:grid-cols-4">
            <div class="col-span-2 md:col-span-1">
              <div class="mb-3 flex items-center gap-2">
                <%= image_tag "/apple-touch-icon.png", alt: "CitySocial", class: "h-8 w-8 rounded-lg" %>
                <span class="bg-gradient-to-r from-brand-500 to-agave-600 bg-clip-text font-display text-lg font-black text-transparent">CitySocial</span>
              </div>
              <p class="text-sm text-ink-muted">Your local community marketplace. Connect, discuss, and trade with people near you.</p>
            </div>
            <% columns.each do |col| %>
              <%= col %>
            <% end %>
          </div>
          <div class="border-t border-line">
            <p class="mx-auto max-w-6xl px-4 py-6 text-center text-sm text-ink-faint">&copy; <%= Date.current.year %> CitySocial. Made for local communities.</p>
          </div>
        </footer>
      ERB

      # A titled column of links. Pass links as [label, href] pairs.
      class ColumnComponent < ViewComponent::Base
        def initialize(title:, links: [])
          @title = title
          @links = links
        end

        erb_template <<~ERB
          <div>
            <h3 class="mb-3 text-sm font-bold text-ink"><%= @title %></h3>
            <ul class="space-y-2">
              <% @links.each do |label, href| %>
                <li><%= link_to label, href, class: "text-sm text-ink-muted transition-colors hover:text-brand-600" %></li>
              <% end %>
            </ul>
          </div>
        ERB
      end
    end
  end
end
