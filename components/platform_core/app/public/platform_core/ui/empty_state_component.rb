module PlatformCore
  module Ui
    class EmptyStateComponent < ViewComponent::Base
      renders_one :action

      def initialize(title:, body: nil)
        @title = title
        @body = body
      end

      erb_template <<~ERB
        <div class="rounded-lg border-2 border-dashed border-line bg-sunken/50 px-6 py-14 text-center">
          <p class="font-display text-xl font-bold text-ink"><%= @title %></p>
          <% if @body %>
            <p class="mx-auto mt-2 max-w-md text-sm text-ink-muted"><%= @body %></p>
          <% end %>
          <% if action? %>
            <div class="mt-5 flex justify-center"><%= action %></div>
          <% end %>
        </div>
      ERB
    end
  end
end
