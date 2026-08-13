# CitySocial — Master Architecture & Agent Conventions

This is a **modular monolith**: one Rails app, one database, many near-independent
"apps" (we call them **modules**) living as mountable engines under `components/`.
This file is the contract. Read it before writing any code. Each module also has
its own nested `CLAUDE.md` — read that too when working inside one.

## The shape of the system

```
host app (thin)        config/routes.rb mounts each module; session + shell only
components/
  platform_core/       SHARED KERNEL. Identity (User), social graph (Follow),
                       public graph API (PlatformCore::Graph), event bus
                       (PlatformCore::EventBus). Depends on nothing.
  feed/                Reference module. Copy its shape for new modules.
  <your modules>/      Generated with `bin/rails g app_module <name>`.
```

## The module contract (non-negotiable — Packwerk enforces it)

1. **A module may depend ONLY on `platform_core`.** Never reference another
   module's classes. Declared in each module's `package.yml`.
2. **Modules talk to each other ONLY via `PlatformCore::EventBus`** — publish an
   event, let interested modules subscribe. The publisher must not know who
   listens. See `components/feed/app/public/feed/publish_post.rb` for the
   canonical example (it emits `feed.post_created`).
3. **Anything a module exposes to others goes in `app/public/<module>/`.**
   That's the only surface siblings may call. Packwerk privacy enforces this.
   Example: `Feed::Timeline`, `PlatformCore::Graph`.
4. **Identity is owned by the kernel.** Modules reference users by id and read
   them through `PlatformCore::Graph`. No module defines its own user table.
5. **Naming:** module `foo` => namespace `Foo`, table prefix `foo_`, mounted at
   `/foo`, controllers inherit `PlatformCore::BaseController`, models inherit
   `Foo::ApplicationRecord`.

## How to add a new module

NEVER hand-roll the engine boilerplate. Run the generator:

```
bin/rails g app_module marketplace
bundle install && bin/rails db:migrate
```

It creates the engine, wires it into the Gemfile + routes, and writes a nested
`CLAUDE.md`. Then fill in models/controllers/views and declare events in
`lib/marketplace/events.rb`.

## Feature scoping rules

Read `northstar.md` whenever choosing or scoping product work. It describes the durable
product destination and should guide relative impact and tradeoffs. It is not a backlog,
an implementation spec, or evidence for a concrete feature; work still needs a grounded
user need, bounded acceptance criteria, and compliance with the module contract.

Every feature must:
- Map to a user persona and an engagement loop (do → others see → notified).
- Live inside exactly one module (or be a new module if it's a full app).
- Cross module boundaries only through events or a sibling's `app/public` API.
- Ship with tests and pass `bin/verify`.
Size: substantial but bounded. One module, one clear flow + its edge cases.

## Design system (every view uses it — no exceptions)

UI is centralized so modules never drift visually. The stack is Tailwind CSS v4
(standalone binary, no Node) + ViewComponent + Hotwire (importmap, no Node).

- **Components:** `PlatformCore::Ui::*` (Button, Card, Table, PageHeader,
  FormField, EmptyState, Badge, Flash, NavBar) live in
  `components/platform_core/app/public/platform_core/ui/`. Views compose these;
  never hand-roll buttons/tables/forms/flash markup.
- **Tokens:** colors/fonts/radii/shadows are defined once in the `@theme` block
  of `app/assets/tailwind/application.css` (e.g. `bg-paper`, `text-ink`,
  `bg-brand-600`, `font-display`). Never hardcode hex values in views.
- **Living catalog:** browse `/design` to see every token and component variant
  before building UI. Keep it updated when adding components.
- **Purge rule:** write Tailwind classes as complete literal strings — never
  build class names by interpolation — or the production build drops them.
  Component variant maps (`VARIANTS = { primary: "bg-brand-600 ..." }`) exist
  for exactly this reason.
- **Scanning:** engine views are picked up by the `@source` globs in
  `application.css`; new modules need no Tailwind config.
- **Local dev:** `bin/dev` runs the server + Tailwind watcher
  (plain `bin/rails s` works too; run `bin/rails tailwindcss:build` after CSS
  or component-class changes).

## Verification checklist (the loop closes on this)

`bin/verify` must pass before any change is considered done. It runs:
- `bin/rails db:test:prepare` + `bundle exec rspec` — behavior is tested.
- `bundle exec packwerk check` — no boundary violations were introduced.
- `bundle exec rubocop` — style holds.
If you add a feature without a test, the loop will (correctly) consider it unfinished.

## Self-improvement

When you discover a rule the hard way (a boundary you almost broke, a pattern that
bit you), append it to `docs/lessons.md`. When you finish a module or milestone,
update `docs/roadmap.md`. These are git-tracked memory: future runs read them.

## Workflow commands (in .claude/commands/)

- `/scope-idea <idea>` — turn a raw idea into a reviewed, bounded spec.
- `/implement-feature <spec or path>` — build an approved spec inside a module.
- `/new-app-module <name> <purpose>` — stand up a whole new app via the generator.
- `/babysit` — run the verify→fix loop until `bin/verify` is green.
- `/update-memory` — fold today's lessons into CLAUDE.md / lessons.md.
- `/build-from-vision <vision>` — decompose a big vision into a phased roadmap.
