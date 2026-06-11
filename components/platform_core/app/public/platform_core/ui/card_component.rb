module PlatformCore
  module Ui
    class CardComponent < ViewComponent::Base
      renders_one :header

      def initialize(padded: true)
        @padded = padded
      end

      erb_template <<~ERB
        <section class="rounded-lg border border-line bg-surface shadow-card">
          <% if header? %>
            <div class="border-b border-line px-5 py-3"><%= header %></div>
          <% end %>
          <div class="<%= @padded ? "p-5" : "" %>"><%= content %></div>
        </section>
      ERB
    end
  end
end
