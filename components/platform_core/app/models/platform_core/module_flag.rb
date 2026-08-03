module PlatformCore
  # Persisted on/off state for an app-module, keyed by module name (e.g.
  # "marketplace"). Absence of a row means "use the catalog default" (enabled).
  # Read/written through the PlatformCore::Modules public API, not directly.
  class ModuleFlag < ApplicationRecord
    self.table_name = "platform_core_modules"

    validates :key, presence: true, uniqueness: true
  end
end
