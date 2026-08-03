module PlatformCore
  module Ui
    # Site chrome. Sticky, blurred bar: brand on the left, pill links next to it,
    # an optional centered search form, then the session slot (user handle, auth
    # buttons) plus a dark-mode toggle on the right.
    class NavBarComponent < ViewComponent::Base
      renders_many :links, lambda { |label, href, active: false|
        classes = if active
                    "text-brand-700 bg-brand-50"
                  else
                    "text-ink-muted hover:text-ink hover:bg-sunken"
                  end
        base = "whitespace-nowrap rounded-full px-3 py-1.5 text-sm font-semibold transition-colors"
        link_to label, href, class: "#{base} #{classes}"
      }
      renders_one :search
      renders_one :session_area

      # On small screens the links wrap onto their own full-width row under the
      # brand + session area; from md: up everything sits on one line.
      erb_template <<~ERB
        <header class="sticky top-0 z-50 border-b border-line bg-surface/80 backdrop-blur-lg">
          <nav class="mx-auto flex max-w-6xl flex-wrap items-center gap-x-4 gap-y-2 px-4 py-2.5">
            <%= link_to root_path, class: "group flex items-center gap-2" do %>
              <%= image_tag "/apple-touch-icon.png", alt: "CitySocial", class: "h-8 w-8 rounded-lg transition-transform group-hover:scale-105" %>
              <span class="hidden bg-gradient-to-r from-brand-500 to-agave-600 bg-clip-text font-display text-xl font-black tracking-tight text-transparent sm:block">CitySocial</span>
            <% end %>

            <% if links.any? %>
              <div class="order-last -mx-2 flex w-full flex-wrap items-center gap-1 md:order-none md:mx-0 md:w-auto">
                <% links.each do |nav_link| %>
                  <%= nav_link %>
                <% end %>
              </div>
            <% end %>

            <% if search? %>
              <div class="flex flex-1 justify-center px-2">
                <div class="w-full max-w-md"><%= search %></div>
              </div>
            <% end %>

            <div class="ml-auto flex items-center gap-2">
              <button type="button"
                      data-controller="theme"
                      data-action="theme#toggle"
                      aria-label="Toggle dark mode"
                      class="rounded-full p-2 text-ink-muted transition-colors hover:bg-sunken hover:text-ink">
                <svg class="h-5 w-5 dark:hidden" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" /></svg>
                <svg class="hidden h-5 w-5 dark:block" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" /></svg>
              </button>
              <%= session_area %>
            </div>
          </nav>
        </header>
      ERB
    end
  end
end
