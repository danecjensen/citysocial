module Messaging
  # PUBLIC: the resident's message inbox, rendered inline on their own profile
  # page via PlatformCore::ProfilePanels. Conversations are read right on the
  # profile instead of behind a separate nav destination. Registered from the
  # engine so the kernel renders it without ever naming a Messaging constant.
  class ProfileInboxComponent < ViewComponent::Base
    LIMIT = 8

    def initialize(user:)
      @user = user
    end

    def conversations
      @conversations ||= Conversation.for_participant(@user.id)
                                     .active_for(@user.id)
                                     .recent
                                     .limit(LIMIT)
                                     .to_a
    end

    def unread_count
      @unread_count ||= Messaging::Inbox.unread_count(@user.id)
    end

    def other_participant(conversation)
      conversation.other_participant(@user.id)
    end

    def last_message(conversation)
      conversation.messages.last
    end

    def unread_for(conversation)
      conversation.unread_count_for(@user.id)
    end

    def conversation_path(conversation)
      "/messaging/conversations/#{conversation.id}"
    end

    def new_conversation_path
      "/messaging/conversations/new"
    end

    erb_template <<~ERB
      <%= render PlatformCore::Ui::CardComponent.new(padded: false) do |card| %>
        <% card.with_header do %>
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h2 class="font-display text-sm font-bold uppercase tracking-wider text-ink-muted">Messages</h2>
              <p class="mt-0.5 text-xs text-ink-faint">
                <%= unread_count.positive? ? helpers.pluralize(unread_count, "unread message") : "You're all caught up." %>
              </p>
            </div>
            <%= render PlatformCore::Ui::ButtonComponent.new(variant: :primary, size: :sm, href: new_conversation_path) do %>
              New message
            <% end %>
          </div>
        <% end %>

        <% if conversations.any? %>
          <ul class="divide-y divide-line">
            <% conversations.each do |conversation| %>
              <% other = other_participant(conversation) %>
              <% message = last_message(conversation) %>
              <% unread = unread_for(conversation) %>
              <li>
                <%= link_to conversation_path(conversation), "aria-label": "Conversation with \#{other&.display_name_or_handle || 'resident'}",
                            class: "flex items-center gap-4 px-5 py-4 transition-colors hover:bg-sunken" do %>
                  <% if other %>
                    <%= render PlatformCore::Ui::AvatarComponent.new(user: other, size: :md, alt: "") %>
                  <% end %>
                  <span class="min-w-0 flex-1">
                    <span class="flex items-center gap-2">
                      <span class="truncate font-display font-bold text-ink">
                        <%= other&.display_name_or_handle || "Resident" %>
                      </span>
                      <% if unread.positive? %>
                        <%= render PlatformCore::Ui::BadgeComponent.new(variant: :brand) do %>
                          <%= unread %>
                        <% end %>
                      <% end %>
                    </span>
                    <% if message %>
                      <span class="mt-0.5 block truncate text-sm <%= unread.positive? ? "font-semibold text-ink" : "text-ink-muted" %>">
                        <%= message.body %>
                      </span>
                      <span class="mt-0.5 block font-mono text-xs text-ink-faint">
                        <%= helpers.time_ago_in_words(message.created_at) %> ago
                      </span>
                    <% end %>
                  </span>
                  <svg class="h-5 w-5 flex-none text-ink-faint" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" /></svg>
                <% end %>
              </li>
            <% end %>
          </ul>
        <% else %>
          <div class="p-5">
            <%= render PlatformCore::Ui::EmptyStateComponent.new(
                  title: "No conversations yet",
                  body: "Start a conversation from a resident's public profile, or send a new message."
                ) %>
          </div>
        <% end %>
      <% end %>
    ERB
  end
end
