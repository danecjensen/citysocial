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

- Tests must NOT require Redis: `config/environments/test.rb` sets `config.active_job.queue_adapter = :test` (app uses `:sidekiq` elsewhere, set in config/application.rb). Any job enqueued in a spec (e.g. Active Storage `AnalyzeJob` on photo attach) otherwise raises `RedisClient::CannotConnectError`. Redis IS installed here but the suite must stay self-contained.
- PG needs trust auth: set 127.0.0.1/::1/local to `trust` in /etc/postgresql/16/main/pg_hba.conf, then reload; config/database.yml uses user postgres, no password.
- `git push` over Bash is blocked here. Push via GitHub MCP: create_branch (from master) → push_files (all changed files, one commit) → create_pull_request (draft). Default branch is `master`.
- Shared UI: PlatformCore::Ui::* in components/platform_core/app/public/. FormFieldComponent supports type: :select. ButtonComponent takes variant/size/href/method/params/confirm/type/aria_label/pressed (no arbitrary classes); toggle buttons (vote, feedback Support) pass pressed: true/false to emit aria-pressed and pair it with an emphasized variant.
- Never hand-roll button/table/form/select/flash markup — compose the Ui components. Update /design (app/views/design/show.html.erb) when adding a component option.
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
- Check suite is `bin/verify`. Tool wrappers vary by container: `bundle exec rspec/rubocop/packwerk` works once `/opt/rbenv/versions/3.3.6/bin` is on PATH; `bin/rspec` binstubs may not exist — try bundle exec first, never commit generated binstubs. In request specs use `Capybara.string(response.body)` + have_css to assert several attrs on one element.
- Test setup: start Postgres (`pg_ctlcluster 16 main start`, trust auth for localhost) and run `bin/rails tailwindcss:build` — specs render the layout which needs the built `tailwind.css`, else every request spec fails with Propshaft::MissingAssetError.
- `PlatformCore::Ui::FormFieldComponent` already renders inline per-attribute validation errors; a form using it for every validated attribute is NOT a missing-error-state gap.
- Icon-only controls need `aria_label:` on `ButtonComponent`; wrap the decorative glyph in `<span aria-hidden="true">`.
- Shared UI lives in `components/platform_core/app/public/platform_core/ui/`; when you change a component's signature, update its example + doc line in `app/views/design/show.html.erb`.
- The `app_module` generator currently needs two RuboCop cleanups after generation: alphabetize its injected Gemfile entry and freeze the generated VERSION constant.

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

## 2026-08-05 — F-003
Outcome: shipped
PR: https://github.com/danecjensen/citysocial/pull/3
Changed: components/platform_core/app/public/platform_core/ui/form_field_component.rb, components/marketplace/app/views/marketplace/listings/_form.html.erb, components/communities/app/views/communities/communities/new.html.erb, app/views/design/show.html.erb, spec/components/platform_core/ui/form_field_component_spec.rb, spec/requests/marketplace_spec.rb
Notes: Default branch was green (the initial bin/verify failure was only the missing tailwind build artifact in a fresh clone, not a master defect). Added type: :select to FormFieldComponent so dropdowns compose the shared component and get inline validation errors; adopted it in the marketplace listing + new-community forms. Ingested no Dane ideas (Inbox empty). 1b gate was open (0 ready items) — proposed F-003..F-006.
Learnings:
- F-004 (vote current-state highlight) and F-005 (external links new tab) both touch files an open PR (F-001, #2) is editing — kept their confidence low and left them ready to sequence after #2 merges, rather than open conflicting PRs.
- FormFieldComponent select: pass collection/include_blank/selected; selected: nil lets Rails preselect the model value so edit forms keep working. Rails renders <select class=... name=...> (class before name) — order-independent regex needed in request specs.
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

## 2026-08-05 10:24 — research
Outcome: produced 4 briefs
Briefs: R-001, R-002, R-003, R-004
Cut: 0 findings dropped outright; 1 finding narrowed (restaurant leaderboard "area/neighborhood" filter angle dropped from R-002 — its only supporting mentions traced back to an unfetchable 403'd aggregator, so it didn't survive verification; cuisine-only survived on Beli App Store review + UX case study + press coverage). 1 finding narrowed (R-004's "needs a new bumped_at column" branch dropped — verifier confirmed `created_at` is never mass-assigned elsewhere, so it doubles as the cooldown clock with zero schema change).
Notes: First research run — research.md had no prior briefs and no prior research run to check against, so both circuit breakers were open. 4 questions drafted, one per module (communities, restaurants, events, marketplace), each grounded in a DB column or engagement-loop gap that already exists in the repo but isn't surfaced in the UI. All 4 scouts produced usable findings on the first pass — no reruns needed. All 4 findings verified (2 clean VERIFIED, 2 NARROWED to a smaller, better-supported claim). Grader (fresh context, Opus) passed all 4: R-001 10/10, R-004 10/10, R-002 8/10 (−2 read-only filter doesn't tighten a do→see→react loop), R-003 8/10 (−2 solo utility, no event-bus publish, no one else sees it). No redraft cycle needed — the 4 questions landed on 4 distinct modules with no overlap or hole to fill.
Learnings:
- Generic "reddit"/"nextdoor" search terms reliably produced unfetchable complaint-board noise this run; direct competitor product docs/help pages (Discourse meta, Craigslist help, Kijiji community docs) and App Store reviews cited cleanly and held up on re-fetch. Weighting keyword sets toward the latter first is worth it.
- A good vein for no-migration findings: grep the target module's model for columns that already exist but are only ever displayed, never filtered/sorted/acted on (communities_comments.score, restaurants_restaurants.cuisine, marketplace_listings.expires_at/created_at all fit this shape).
- The grader's engagement-loop deduction (−2) lands hardest on read-only/solo-utility features (filters, calendar export) versus features that make an existing vote/action visibly affect ordering (comment top-sort, listing renew) — bias future question drafts toward the latter shape when a choice exists.

## 2026-08-05 11:04 — research
Outcome: skipped (queue full: 4 fresh briefs on current remote master)
Briefs: none
Cut: 1 graded profile candidate discarded at the queue circuit breaker
Notes: Shell DNS failure prevented refreshing the stale local origin/master before
research. The connected GitHub app revealed R-001 through R-004 already fresh on
current remote master at the publish gate, so no new brief was recorded.

## 2026-08-05 — master-red fix (test env queue adapter)
Outcome: shipped (Phase 0 defect fix; skipped Phases 1-2 per routine)
PR: https://github.com/danecjensen/citysocial/pull/11
Changed: config/environments/test.rb, spec/config/active_job_adapter_spec.rb
Notes: Default branch bin/verify was genuinely RED — 6 restaurants specs failed with
RedisClient::CannotConnectError. Root cause: PR #6 added Active Storage photos, whose
AnalyzeJob enqueues via the globally-configured `:sidekiq` adapter
(config/application.rb:15); config/environments/test.rb never overrode it, so any
attachment in a spec tried to reach Redis. Fix: set the test env's
`config.active_job.queue_adapter = :test` (in-memory), the Rails-idiomatic choice — no
new dependency, no schema, no secrets. EventBus subscribers are inline by default
(async:true ones use ActiveJob), so this changes no passing behavior. Added a small
config guard spec so a revert fails loudly with a clear reason instead of a Redis error.
Full suite now 103 examples, 0 failures; packwerk + rubocop clean. Did NOT start Redis
locally (would only paper over the defect for one environment). Backlog untouched — this
was a Phase 0 fix, not a scheduled feature.
Learnings:
- Promoted to Codebase Patterns: tests must not depend on Redis; test env uses the
  ActiveJob `:test` adapter.
## 2026-08-05 12:11 — F-007
Outcome: shipped
PR: https://github.com/danecjensen/citysocial/pull/10
Changed: components/platform_core/app/models/platform_core/user.rb, components/platform_core/app/controllers/platform_core/profiles_controller.rb, components/platform_core/app/public/platform_core/graph.rb, components/platform_core/app/public/platform_core/ui/avatar_component.rb, components/platform_core/app/views/platform_core/profiles/, components/platform_core/db/migrate/20260805114500_add_public_profile_to_platform_core_users.rb, app/views/layouts/application.html.erb, components/feed/app/views/feed/posts/index.html.erb, components/communities/app/views/communities/, components/marketplace/app/views/marketplace/listings/show.html.erb, spec/, routines/backlog.json, docs/roadmap.md
Notes: Capability lane. Shipped the human-priority public resident profile MVP with safe optional fields, validated avatar, discoverable author links, a PII-safe Graph snapshot, and platform_core.profile_updated. Draft PR opened with verification incomplete: Packwerk, RuboCop, Zeitwerk, routes, Rails ERB compilation, Ruby syntax, Tailwind, and diff checks passed; PostgreSQL-backed migration/spec execution was blocked by managed TCP denial before examples loaded.
Learnings:
- Resolve Ruby through the repository's active rbenv shims and .ruby-version; the old hardcoded /opt/rbenv path can silently fall back to macOS Ruby.

## 2026-08-05 17:16 — F-008
Outcome: shipped
PR: https://github.com/danecjensen/citysocial/pull/12
Changed: components/notifications/, app/views/layouts/application.html.erb, components/platform_core/app/public/platform_core/modules.rb, config/routes.rb, db/schema.rb, spec/, routines/backlog.json, routines/research.md, docs/roadmap.md, docs/lessons.md
Notes: Capability lane. Generated the Notifications engine and shipped a durable follower activity inbox consuming feed.post_created and communities.post_created asynchronously through the event bus. Followers get idempotent, owner-only notifications with unread shell count, empty state, read-through, and mark-all-read; no sibling model references or PII are stored. Draft PR opened with verification incomplete: Packwerk, RuboCop, Zeitwerk, Rails boot/routes/event wiring, ERB compilation, Ruby syntax, Tailwind, factory load, JSON, and diff checks passed; PostgreSQL denial blocked migration execution, screenshots, and all RSpec examples before they ran. Consumed R-001 through R-004 as F-009 through F-012 for future module-feature runs.
Learnings:
- The app_module generator currently inserts a new path gem out of alphabetical order and emits a mutable VERSION constant; correct both before RuboCop.
## 2026-08-05 23:25 — F-004
Outcome: shipped
PR: https://github.com/danecjensen/citysocial/pull/13
Changed: components/platform_core/app/public/platform_core/ui/button_component.rb, components/communities/app/views/communities/posts/_vote.html.erb, components/communities/app/views/communities/communities/show.html.erb, components/communities/app/views/communities/posts/show.html.erb, app/views/design/show.html.erb, spec/components/platform_core/ui/button_component_spec.rb, spec/requests/communities_spec.rb
Notes: Master was green here (131 examples) — the initial container churn was only env setup. F-001 (PR #2) merged, so F-004's ButtonComponent-conflict hold lifted and it rescored to the top (1.7). Added an optional `pressed:` to ButtonComponent (emits aria-pressed; omitted = attribute absent) and drove the highlight from the `_vote` partial: up-active = :primary, down-active = :danger, else :ghost, wired through my_vote on all three surfaces (post list, show, comments). Full suite green: 137 examples, packwerk + rubocop clean.
1a: DanesIdeas Inbox empty — nothing ingested. 1b (gate open, 3 ready<5): the easy grounded veins are drained (no TODO/FIXME, every collection view guards its zero-case, all images have alt text, events pagination guarded). Proposed 2 genuinely-grounded items rather than pad to 3 with speculation: F-013 (feedback Support toggle needs aria-pressed, enabled by this PR — score 2.55, next-run top pick) and F-014 (the per-row vote_value_for N+1 this PR introduces — score 0.75, honest but below threshold). Did NOT re-consume research briefs R-001..R-004: open PR #12 (codex F-008 notifications) already consumed them into F-009..F-012 on its branch, so I reserved the F-008..F-012 id range (next_id jumped to 15) to avoid id collisions when #12 merges.
Learnings:
- ButtonComponent `pressed:` toggle state: pass true/false to emit aria-pressed; leave nil for non-toggle buttons so the attribute is omitted. Any button whose meaning toggles (vote, feedback Support) should set it.
- In request specs, `Capybara.string(response.body)` + have_css lets you assert several attributes on the SAME element (e.g. button[aria-label='Upvote'][aria-pressed='true'].bg-brand-600) — more robust than multiple `include` checks that don't prove co-location.
- Ruby -e JSON.parse chokes on the em-dashes in backlog.json under US-ASCII; read with encoding: "UTF-8" when validating.
