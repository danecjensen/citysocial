module PlatformCore
  # The kernel's PUBLIC registry of profile panels.
  #
  # A resident's own profile page can host module-owned panels rendered inline —
  # e.g. messaging drops its whole inbox there so conversations are read on the
  # profile instead of behind a separate nav destination. The kernel owns the
  # profile page but must not know which modules exist, so the dependency is
  # inverted: each module registers its own panel component from its engine and
  # the profile view renders whatever is in the registry. Nothing here references
  # a module constant.
  #
  # Register from the engine's `to_prepare` block (re-runs on reload, so the
  # registry survives code reloading):
  #
  #   config.to_prepare do
  #     PlatformCore::ProfilePanels.register(
  #       key: "messaging_inbox", module_key: "messaging", position: 10
  #     ) { |user| Messaging::ProfileInboxComponent.new(user: user) }
  #   end
  #
  # The block is called at render time with the profile owner (a PlatformCore
  # user); resolving the component lazily keeps this reload-safe and keeps the
  # kernel from ever naming a module constant. Panels are shown only on the
  # owner's own profile, and a panel whose module is switched off is hidden.
  module ProfilePanels
    Panel = Struct.new(:key, :module_key, :position, :builder, keyword_init: true) do
      def component(user)
        builder.call(user)
      end
    end

    module_function

    def register(key:, module_key: nil, position: 100, &builder)
      raise ArgumentError, "profile panel #{key} needs a component block" unless builder

      registry[key.to_s] = Panel.new(
        key: key.to_s, module_key: module_key&.to_s, position: position, builder: builder
      )
    end

    # Panels belonging to a switched-off module are hidden, in stable display order.
    def all
      registry.values
              .select { |panel| panel.module_key.nil? || PlatformCore::Modules.enabled?(panel.module_key) }
              .sort_by { |panel| [panel.position, panel.key] }
    end

    def registry
      @registry ||= {}
    end
  end
end
