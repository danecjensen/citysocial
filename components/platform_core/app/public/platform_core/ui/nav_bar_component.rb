module PlatformCore
  module Ui
    # Site chrome. Links go on the left after the brand; the session slot
    # (user handle, auth buttons) renders on the right.
    class NavBarComponent < ViewComponent::Base
      renders_many :links, lambda { |label, href, active: false|
        classes = if active
                    "text-brand-700 bg-brand-50"
                  else
                    "text-ink-muted hover:text-ink hover:bg-sunken"
                  end
        link_to label, href, class: "rounded-sm px-3 py-1.5 text-sm font-bold transition-colors #{classes}"
      }
      renders_one :session_area

      erb_template <<~ERB
        <header class="border-b-2 border-ink bg-surface">
          <nav class="mx-auto flex max-w-5xl items-center gap-6 px-4 py-3">
            <%= link_to root_path, class: "font-display text-xl font-black tracking-tight text-ink hover:text-brand-700 transition-colors" do %>
              City<span class="text-brand-600">Social</span>
            <% end %>
            <div class="flex items-center gap-1">
              <% links.each do |nav_link| %>
                <%= nav_link %>
              <% end %>
            </div>
            <div class="ml-auto flex items-center gap-3">
              <%= session_area %>
            </div>
          </nav>
        </header>
      ERB
    end
  end
end
