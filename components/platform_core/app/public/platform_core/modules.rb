module PlatformCore
  # The kernel's PUBLIC registry of app-modules. Other code (the host layout,
  # BaseController, the admin UI) calls PlatformCore::Modules.*, never the
  # ModuleFlag model directly.
  #
  # The CATALOG below is the source of truth for *which* modules exist and their
  # nav metadata; the platform_core_modules table stores only the on/off flag
  # per key (absent row => enabled). "platform_core" itself is the kernel and is
  # never toggleable.
  module Modules
    module_function

    Entry = Struct.new(:key, :label, :path, :nav, :enabled, keyword_init: true)

    CATALOG = [
      { key: "feed",         label: "Feed",         path: "/feed",         nav: true },
      { key: "restaurants",  label: "Restaurants",  path: "/restaurants",  nav: true },
      { key: "communities",  label: "Communities",  path: "/communities",  nav: true },
      { key: "marketplace",  label: "Marketplace",  path: "/marketplace",  nav: true },
      { key: "events",       label: "Events",       path: "/events",       nav: true },
      { key: "messaging",    label: "Messages",     path: "/messaging",    nav: true },
      { key: "feedback",     label: "Feedback",     path: "/feedback",     nav: true }
    ].freeze

    def all
      flags = flags_by_key
      CATALOG.map do |entry|
        Entry.new(**entry, enabled: flags.fetch(entry[:key], true))
      end
    end

    def nav_modules
      all.select { |m| m.nav && m.enabled }
    end

    # Unknown keys (e.g. the "platform_core" kernel) are always enabled.
    def enabled?(key)
      key = key.to_s
      return true unless CATALOG.any? { |e| e[:key] == key }

      flags_by_key.fetch(key, true)
    end

    def enable!(key)
      set(key, true)
    end

    def disable!(key)
      set(key, false)
    end

    def set(key, enabled)
      flag = PlatformCore::ModuleFlag.find_or_initialize_by(key: key.to_s)
      flag.update!(enabled: enabled)
    end

    # { "marketplace" => false, ... }. Guarded so early boot / pre-migration
    # calls (before the table exists) fall back to catalog defaults.
    def flags_by_key
      PlatformCore::ModuleFlag.pluck(:key, :enabled).to_h
    rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
      {}
    end
  end
end
