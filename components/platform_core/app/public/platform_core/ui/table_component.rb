module PlatformCore
  module Ui
    # Usage:
    #   columns = ["Rank", "Name", { label: "Elo", numeric: true }]
    #   <%= render PlatformCore::Ui::TableComponent.new(columns:) do |table| %>
    #     <% table.with_row do |row| %>
    #       <% row.with_cell { "1" } %>
    #       <% row.with_cell(numeric: true) { "1742" } %>
    #     <% end %>
    #   <% end %>
    class TableComponent < ViewComponent::Base
      renders_many :rows, "PlatformCore::Ui::TableComponent::RowComponent"

      def initialize(columns:)
        @columns = columns.map { |c| c.is_a?(Hash) ? c : { label: c } }
      end

      erb_template <<~ERB
        <div class="overflow-x-auto rounded-lg border border-line bg-surface shadow-card">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b-2 border-ink bg-sunken/60">
                <% @columns.each do |col| %>
                  <th class="px-4 py-2.5 text-xs font-bold uppercase tracking-wider text-ink-muted <%= col[:numeric] ? "text-right" : "text-left" %>"><%= col[:label] %></th>
                <% end %>
              </tr>
            </thead>
            <tbody class="divide-y divide-line">
              <% rows.each do |row| %>
                <%= row %>
              <% end %>
            </tbody>
          </table>
        </div>
      ERB

      class RowComponent < ViewComponent::Base
        renders_many :cells, lambda { |numeric: false, &block|
          tag.td(class: "px-4 py-3 #{numeric ? 'text-right font-mono tabular-nums' : 'text-left'}", &block)
        }

        erb_template <<~ERB
          <tr class="transition-colors hover:bg-brand-50/40">
            <% cells.each do |cell| %>
              <%= cell %>
            <% end %>
          </tr>
        ERB
      end
    end
  end
end
