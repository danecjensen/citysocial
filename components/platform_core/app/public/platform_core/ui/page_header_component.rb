module PlatformCore
  module Ui
    class PageHeaderComponent < ViewComponent::Base
      renders_one :actions

      def initialize(title:, subtitle: nil)
        @title = title
        @subtitle = subtitle
      end

      erb_template <<~ERB
        <div class="mb-8 flex flex-wrap items-end justify-between gap-4 border-b border-line pb-5">
          <div>
            <h1 class="font-display text-3xl font-black tracking-tight text-ink"><%= @title %></h1>
            <% if @subtitle %>
              <p class="mt-1 text-sm text-ink-muted"><%= @subtitle %></p>
            <% end %>
          </div>
          <% if actions? %>
            <div class="flex items-center gap-2"><%= actions %></div>
          <% end %>
        </div>
      ERB
    end
  end
end
