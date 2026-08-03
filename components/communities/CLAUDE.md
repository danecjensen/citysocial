# Communities module

Nested memory for this module. Read alongside the root CLAUDE.md.

## Boundaries
- Depends ONLY on `platform_core`. Never reference another module's classes.
- Cross-module communication goes through `PlatformCore::EventBus` (see lib/communities/events.rb).
- Anything other modules need from here goes in `app/public/communities/`.

## Conventions
- Controllers inherit from `PlatformCore::BaseController`.
- Models inherit from `Communities::ApplicationRecord` and use the table prefix `communities_`.
- Every new event must be documented in `events.rb`.

## UI (shared design system)
- Build views from `PlatformCore::Ui::*` components (Button, Card, Table,
  PageHeader, FormField, EmptyState, Badge, Flash) plus Tailwind token
  utilities (`bg-paper`, `text-ink`, `bg-brand-600`, `font-display`, ...).
  Browse the living catalog at `/design` before writing any view.
- Never hand-roll buttons, tables, forms, or flash markup, and never hardcode
  hex colors — tokens live in `app/assets/tailwind/application.css`.
- Write Tailwind classes as complete literal strings (no string interpolation
  to build class names) or the production build purges them.
- This module's views are scanned automatically via the `components/*` glob;
  no Tailwind config changes are needed when adding views here.
