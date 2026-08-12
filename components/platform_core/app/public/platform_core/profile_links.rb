module PlatformCore
  # The kernel's PUBLIC registry of personal profile shortcuts.
  #
  # A resident's own profile page is their account hub — the standard place
  # social apps surface *your* personal inboxes (messages, notifications)
  # instead of bolting them onto the global nav for everyone. The kernel owns
  # the profile page but must not know which modules exist, so the dependency is
  # inverted: each module registers its own shortcut from its engine and the
  # profile view renders whatever is in the registry. Nothing here references a
  # module constant.
  #
  # Register from the engine's `to_prepare` block (re-runs on reload, so the
  # registry survives code reloading):
  #
  #   config.to_prepare do
  #     PlatformCore::ProfileLinks.register(
  #       key: "messages", label: "Messages", path: "/messaging/",
  #       module_key: "messaging", position: 10,
  #       description: "Your private conversations with neighbors.",
  #       icon: "M3 8l7.89 5.26 ..."
  #     ) { |user_id| Messaging::Inbox.unread_count(user_id) }
  #   end
  #
  # `icon` is the SVG path data (the `d` attribute) for a single-path, 24x24
  # stroked glyph; the profile view wraps it in a consistently styled <svg>.
  #
  # The unread block is called at render time with the viewer's id; resolving it
  # lazily keeps the kernel from ever naming a module's inbox constant. A link
  # whose module is switched off is hidden, so the profile never links to a
  # surface BaseController would refuse to serve.
  module ProfileLinks
    Link = Struct.new(:key, :label, :path, :description, :icon, :module_key, :position, :counter,
                      keyword_init: true) do
      # Unread badge count for the given resident. Links without a counter (or
      # whose counter misbehaves) simply show no badge.
      def unread_count(user_id)
        return 0 unless counter

        counter.call(user_id).to_i
      end
    end

    module_function

    def register(key:, label:, path:, description: nil, icon: nil, module_key: nil, position: 100, &counter)
      registry[key.to_s] = Link.new(
        key: key.to_s, label: label, path: path, description: description,
        icon: icon, module_key: module_key&.to_s, position: position, counter: counter
      )
    end

    # Links belonging to a switched-off module are hidden, in stable display order.
    def all
      registry.values
              .select { |link| link.module_key.nil? || PlatformCore::Modules.enabled?(link.module_key) }
              .sort_by { |link| [link.position, link.label] }
    end

    def registry
      @registry ||= {}
    end
  end
end
