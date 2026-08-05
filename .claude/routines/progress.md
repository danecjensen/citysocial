# Progress Log

Append-only. The routine writes here at the end of every run, including failed runs.
Do not reorganize or summarize this file — the raw sequence is the audit trail.

## Codebase Patterns

<!--
Read first on every run. Hard cap: 20 lines. When adding one, prune the least useful.
Only general, reusable knowledge belongs here — not story-specific detail.

Examples of the right kind of line:
- Service objects live in app/services and always return a Result struct
- Migrations are never written by the routine; they are flagged for a human
- Feature specs need the dev server on :3000
-->

- Env setup a fresh clone needs before `bin/verify` works: `bundle install`, then put
  gem exe wrappers on PATH — `export PATH="/opt/rbenv/versions/3.3.6/bin:$PATH"` (else
  `bundle exec rspec/rubocop/packwerk` = "command not found"); start Postgres with
  `pg_ctlcluster 16 main start` and set its pg_hba host lines (127.0.0.1/::1) to `trust`
  (app connects as `postgres` with empty password); run `bin/rails tailwindcss:build`
  (builds/tailwind.css is gitignored) or request specs 500 on the missing asset.
- Convention: every index/collection view guards with `<% if @coll.any? %>` and renders
  `PlatformCore::Ui::EmptyStateComponent` (optional `empty.with_action`) for the zero-case.
- Views compose only `PlatformCore::Ui::*` components + Tailwind tokens; write class
  strings as literals (never interpolate) or the standalone Tailwind build purges them.
- Modules cross boundaries only via `PlatformCore::EventBus` or a sibling's `app/public`
  API; a module references users by id through `PlatformCore::Graph`, never the User model.
- Check suite is `bin/verify`; in this sandbox `bundle exec <exe>` is broken, so run tools via generated binstubs (`bin/rspec`/`bin/rubocop`/`bin/packwerk`) — but do NOT commit those binstubs.
- Test setup: start Postgres (`pg_ctlcluster 16 main start`, trust auth for localhost) and run `bin/rails tailwindcss:build` — specs render the layout which needs the built `tailwind.css`, else every request spec fails with Propshaft::MissingAssetError.
- `PlatformCore::Ui::FormFieldComponent` already renders inline per-attribute validation errors; a form using it for every validated attribute is NOT a missing-error-state gap.
- Icon-only controls need `aria_label:` on `ButtonComponent`; wrap the decorative glyph in `<span aria-hidden="true">`.
- Shared UI lives in `components/platform_core/app/public/platform_core/ui/`; when you change a component's signature, update its example + doc line in `app/views/design/show.html.erb`.

---

## Runs

<!--
Format, appended newest-last:

## 2026-08-01 14:03 — F-041
Outcome: shipped | failed | blocked | skipped
PR: <url or none>
Changed: path/one.rb, path/two.tsx
Notes: one or two lines on what actually happened
Learnings:
- <only if genuinely reusable>
-->

## 2026-08-04 — F-002
Outcome: shipped
PR: https://github.com/danecjensen/citysocial/pull/1
Changed: components/restaurants/app/views/restaurants/leaderboard/index.html.erb, spec/requests/restaurants_spec.rb
Notes: Default branch was healthy — the initial `bin/verify` failure was purely
container setup (gem exe wrappers off PATH, Postgres down, tailwind.css unbuilt), not
code; fixed the env, then shipped the leaderboard empty state (the one index view still
missing its zero-case). DanesIdeas inbox was empty; 1b gate was open (0 ready), so seeded
the backlog with F-001 (feed composer, next up at 1.70), F-003 (vote-button a11y), and
F-004 (feed timeline N+1, below threshold at 0.975).
Learnings:
- Env-setup steps promoted to Codebase Patterns above.
## 2026-08-04 — F-001
Outcome: shipped
PR: https://github.com/danecjensen/citysocial/pull/2
Changed: components/platform_core/app/public/platform_core/ui/button_component.rb, components/communities/app/views/communities/posts/_vote.html.erb, app/views/design/show.html.erb, spec/components/platform_core/ui/button_component_spec.rb, spec/requests/communities_spec.rb
Notes: Empty backlog + empty DanesIdeas inbox, so ran 1b (gate open) and proposed 5 grounded items from an Explore sweep. Picked the highest scorer (1.8): icon-only vote buttons had no accessible name. Added aria_label: to the shared ButtonComponent, applied it to the vote partial, documented it in /design. Full suite 89 examples green, packwerk + rubocop clean.
Learnings:
- Verified-away slop: the explorer flagged communities community/post forms as "missing error state," but both use FormFieldComponent for every validated attribute, so errors already render inline. Cut, not queued — do not re-propose. Same for login/comment forms (flash.now via layout).
- Backlog now holds F-002..F-005 (leaderboard/admin empty states, feed compose dead-end, author N+1) as grounded ready items for future runs.
