# Developer

A CitySocial app-module. Mounted at `/developer`. Depends only on
`platform_core`. Communicates with other modules via `PlatformCore::EventBus`.

The portal is restricted to administrators and provides direct, validation-aware
CRUD for every application ActiveRecord model. Each model page shows its records
in a sortable, paginated table and exports the complete table as CSV.
