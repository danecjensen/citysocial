module PlatformCore
  module Ui
    # Site chrome. Sticky, blurred bar: brand on the left, pill links next to it,
    # an optional centered search form, then the session slot (user handle, auth
    # buttons) plus a dark-mode toggle on the right.
    #
    # Responsive: from lg: up everything sits on one inline row. Below lg the bar
    # collapses to a minimal top row (brand + theme toggle + hamburger) and the
    # links, search and session area move into a toggleable drawer driven by the
    # `nav` Stimulus controller.
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
      # Overflow nav destinations. Rendered as stacked rows inside the hamburger
      # "More" dropdown instead of as top-level pills.
      renders_many :menu_links, lambda { |label, href, active: false|
        classes = if active
                    "text-brand-700 bg-brand-50"
                  else
                    "text-ink-muted hover:text-ink hover:bg-sunken"
                  end
        base = "block rounded-xl px-3 py-2 text-sm font-semibold transition-colors"
        link_to label, href, class: "#{base} #{classes}"
      }
      renders_one :search
      renders_one :session_area

      erb_template <<~ERB
        <header class="sticky top-0 z-50 border-b border-line bg-surface/80 backdrop-blur-lg"
                data-controller="nav"
                data-action="keydown.esc@window->nav#close click@window->nav#closeOnOutside">
          <nav class="mx-auto flex max-w-6xl flex-col gap-y-3 px-4 py-2.5 lg:flex-row lg:flex-wrap lg:items-center lg:gap-x-4 lg:gap-y-2">
            <%# Top row. On lg: the wrapper dissolves (contents) so the brand sits
                directly in the nav flex row; the theme + hamburger cluster is
                mobile-only. %>
            <div class="flex items-center gap-3 lg:contents">
              <%= link_to root_path, class: "group flex shrink-0 items-center gap-2" do %>
                <%= image_tag "/apple-touch-icon.png", alt: "CitySocial", class: "h-8 w-8 rounded-lg transition-transform group-hover:scale-105" %>
                <span class="bg-gradient-to-r from-brand-500 to-agave-600 bg-clip-text font-display text-xl font-black tracking-tight text-transparent">CitySocial</span>
              <% end %>

              <div class="ml-auto flex items-center gap-1 lg:hidden">
                <button type="button"
                        data-controller="theme"
                        data-action="theme#toggle"
                        aria-label="Toggle dark mode"
                        class="inline-flex rounded-full p-2 text-ink-muted transition-colors hover:bg-sunken hover:text-ink">
                  <svg class="h-5 w-5 dark:hidden" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" /></svg>
                  <svg class="hidden h-5 w-5 dark:block" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" /></svg>
                </button>
                <button type="button"
                        data-nav-target="button"
                        data-action="nav#toggle"
                        aria-expanded="false"
                        aria-controls="primary-nav"
                        aria-label="Toggle navigation menu"
                        class="inline-flex rounded-full p-2 text-ink-muted transition-colors hover:bg-sunken hover:text-ink">
                  <svg data-nav-target="openIcon" class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" /></svg>
                  <svg data-nav-target="closeIcon" class="hidden h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>
                </button>
              </div>
            </div>

            <%# Collapsible region. Mobile: hidden until the hamburger toggles it,
                then stacked full-width. lg:+ always shown (lg:flex beats hidden)
                and reflowed into the inline row. %>
            <div id="primary-nav"
                 data-nav-target="panel"
                 class="hidden flex-col gap-y-3 pb-2 lg:flex lg:flex-1 lg:flex-row lg:flex-wrap lg:items-center lg:gap-x-4 lg:gap-y-2 lg:pb-0">
              <% if links.any? %>
                <div class="flex flex-col items-start gap-1 lg:flex-row lg:flex-wrap lg:items-center">
                  <% links.each do |nav_link| %>
                    <%= nav_link %>
                  <% end %>
                </div>
              <% end %>

              <% if search? %>
                <div class="order-first flex w-full lg:order-none lg:flex-1 lg:justify-center lg:px-2">
                  <div class="w-full lg:max-w-md"><%= search %></div>
                </div>
              <% end %>

              <div class="flex flex-wrap items-center gap-2 lg:ml-auto lg:flex-nowrap">
                <% if menu_links.any? %>
                  <details class="relative w-full lg:w-auto"
                           data-controller="menu"
                           data-action="keydown.esc@window->menu#close click@window->menu#closeOnOutside">
                    <summary class="flex cursor-pointer list-none items-center gap-1.5 rounded-full px-3 py-1.5 text-sm font-semibold text-ink-muted transition-colors hover:bg-sunken hover:text-ink [&::-webkit-details-marker]:hidden" aria-label="More menu">
                      <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" /></svg>
                      <span>More</span>
                    </summary>
                    <div class="absolute left-0 right-0 z-10 mt-2 rounded-2xl border border-line bg-surface p-2 shadow-card lg:left-auto lg:w-56">
                      <% menu_links.each do |menu_link| %>
                        <%= menu_link %>
                      <% end %>
                    </div>
                  </details>
                <% end %>
                <button type="button"
                        data-controller="theme"
                        data-action="theme#toggle"
                        aria-label="Toggle dark mode"
                        class="hidden rounded-full p-2 text-ink-muted transition-colors hover:bg-sunken hover:text-ink lg:inline-flex">
                  <svg class="h-5 w-5 dark:hidden" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" /></svg>
                  <svg class="hidden h-5 w-5 dark:block" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" /></svg>
                </button>
                <%= session_area %>
              </div>
            </div>
          </nav>
        </header>
      ERB
    end
  end
end
