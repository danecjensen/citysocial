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
        base = "whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-bold transition-colors"
        link_to label, href, class: "#{base} #{classes}"
      }
      renders_one :session_area

      # On small screens the links wrap onto their own full-width row under
      # the brand + session area; from sm: up everything sits on one line.
      erb_template <<~ERB
        <header class="border-b-2 border-ink bg-surface">
          <nav class="mx-auto flex max-w-5xl flex-wrap items-center gap-x-6 gap-y-1 px-4 py-3">
            <%= link_to root_path, class: "font-display text-xl font-black tracking-tight text-ink hover:text-brand-700 transition-colors" do %>
              City<span class="text-brand-600">Social</span>
            <% end %>
            <% if links.any? %>
              <div class="order-last -mx-3 flex w-full flex-wrap items-center gap-1 sm:order-none sm:mx-0 sm:w-auto">
                <% links.each do |nav_link| %>
                  <%= nav_link %>
                <% end %>
              </div>
            <% end %>
            <div class="ml-auto flex items-center gap-3">
              <%= session_area %>
            </div>
          </nav>
        </header>
      ERB
    end
  end
end
