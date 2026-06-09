# Restaurants module

Nested memory for this module. Read alongside the root CLAUDE.md.

## Boundaries
- Depends ONLY on `platform_core`. Never reference another module's classes.
- Cross-module communication goes through `PlatformCore::EventBus` (see lib/restaurants/events.rb).
- Anything other modules need from here goes in `app/public/restaurants/`.

## Conventions
- Controllers inherit from `PlatformCore::BaseController`.
- Models inherit from `Restaurants::ApplicationRecord` and use the table prefix `restaurants_`.
- Every new event must be documented in `events.rb`.
