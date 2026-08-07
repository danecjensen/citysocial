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
- Check suite is `bin/verify`. Tool wrappers vary by container: `bundle exec rspec/rubocop/packwerk` works once `/opt/rbenv/versions/3.3.6/bin` is on PATH; `bin/rspec` binstubs may not exist (generate with `bundle binstubs`, but never commit them). In request specs use `Capybara.string(response.body)` + have_css to assert several attrs on one element.
- A fresh clone lags in-flight PR branches: in Phase 0, reconcile each `ready` item against the open PR list and never rebuild an item that already has an open PR (mark it `done`). Pick items in modules with zero file overlap with open PRs to avoid merge conflicts.
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
## 2026-08-06 — F-012
Outcome: shipped
PR: https://github.com/danecjensen/citysocial/pull/14
Changed: components/marketplace/app/models/marketplace/listing.rb, components/marketplace/app/controllers/marketplace/listings_controller.rb, components/marketplace/config/routes.rb, components/marketplace/app/views/marketplace/listings/show.html.erb, spec/models/marketplace/listing_spec.rb, spec/requests/marketplace_spec.rb, routines/backlog.json, routines/research.md, routines/progress.md
Notes: Master was fully green (rspec 131/0, packwerk + rubocop clean). No unprocessed
DanesIdeas (Inbox empty). Consumed research brief R-004 (grader 10/10) as F-012:
owner-only marketplace listing renewal. renew! resets created_at (doubles as the 48h
cooldown clock — no migration) and pushes expires_at 30 days out; Renew button shows only
when renewable?. Full suite 136 examples, 0 failures. Chose R-004 because it is the
top-graded fresh brief in a module with ZERO file overlap with the two open draft PRs
(#12 notifications, #13 vote-state), unlike the existing ready items F-005/F-006 which
both collide with #13's ButtonComponent / communities-view edits.
Learnings:
- Two automation tracks are diverging on master: a codex track opened PR #12 which BUILT
  the notifications module (F-008) and QUEUED F-009-F-012 (from R-001..R-004, status ready)
  but implemented none of the four and never touched research.md. To avoid ID collisions,
  reused codex's assigned id F-012 for R-004 and bumped next_id to 13. Expect a
  human-resolved backlog.json merge conflict if #12 lands.
- Reconciled F-004: an earlier session already opened draft PR #13 for it, but master's
  backlog still showed it ready. Marked it done so it isn't re-picked. Check open PRs
  against ready-item state every run — the fresh clone lags in-flight PR branches.

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

## 2026-08-06 — F-013
Outcome: shipped
PR: https://github.com/danecjensen/citysocial/pull/19
Changed: components/feedback/app/views/feedback/submissions/_submission.html.erb, components/feedback/app/views/feedback/submissions/show.html.erb, spec/requests/feedback_spec.rb
Notes: Master green on arrival (137 examples) — the F-004/PR #13 merge landed ButtonComponent#pressed:, lifting F-013's hold, so it was the top ready item (2.55). Wired `pressed: supported` on the list partial and `pressed: @supported` on the show page; the existing variant/label swap and supports_count were left untouched. New request spec asserts aria-pressed='true' on a supported item (list + show) and 'false' on an unsupported one via Capybara.string + have_css. Full suite green: 138 examples, packwerk + rubocop clean. No /design change — `pressed:` was already documented by F-004.
1a: DanesIdeas Inbox empty — nothing ingested. 1b (gate open, 4 ready<5): added 0 items. The easy grounded veins stay drained (no TODO/FIXME anywhere; collection views guard their zero-case), and the only outward-looking source — research briefs R-001..R-004 — are still `fresh` on master but already in flight on open PRs #12/#14/#16 under the codex-track F-009..F-012 ids the prior run reserved (next_id=15). Re-proposing them would be duplicate churn, so I left the backlog as-is rather than pad.
Learnings:
- (none new — the ButtonComponent `pressed:` toggle pattern is already in Codebase Patterns; F-013 was its second, clean application. Feedback Support show-page button has no aria_label because its text content ("Support this"/"Remove support") is its accessible name — only icon-only toggles need both aria_label and pressed.)
## 2026-08-06 05:09 — F-005
Outcome: shipped
PR: https://github.com/danecjensen/citysocial/pull/16
Changed: components/platform_core/app/public/platform_core/ui/button_component.rb, components/events/app/views/events/events/show.html.erb, app/views/design/show.html.erb, spec/components/platform_core/ui/button_component_spec.rb, spec/requests/events_spec.rb, routines/backlog.json
Notes: Capability was the preferred lane, but profiles are shipped, notifications and messaging are already represented by open draft PRs, and research briefs R-001 through R-004 are reserved by F-009 through F-012. Used the authorized smaller-feature fallback and shipped the highest-scoring unclaimed item: event ticket links now preserve CitySocial in the original tab while opening with noopener/noreferrer. DanesIdeas Inbox was empty; research.md was unchanged. Verification incomplete only because the managed environment denied PostgreSQL before examples: Packwerk, RuboCop, Zeitwerk, Ruby/ERB checks, Tailwind, backlog integrity, and diff checks passed.
## 2026-08-05 23:33 — F-013
Outcome: shipped
PR: https://github.com/danecjensen/citysocial/pull/15
Changed: components/messaging/, components/platform_core/app/public/platform_core/graph.rb, components/platform_core/app/public/platform_core/modules.rb, components/platform_core/app/views/platform_core/profiles/show.html.erb, config/routes.rb, db/schema.rb, spec/, routines/backlog.json, docs/roadmap.md
Notes: Product fallback lane. The preferred late-night Capability lane had no unreserved evidence-backed candidate: the human-priority profile capability is shipped, notifications F-008 is already represented by open PR #12, and the remaining research queue contains module features. The third consecutive Codex implementation therefore satisfied the product-cadence requirement with the roadmap-backed Messaging MVP: generated engine, canonical one-to-one threads, private replies, unread/read state, profile entry point, owner scoping, a PII-safe handle lookup, and a content-free messaging.message_created event. Draft PR opened with verification incomplete: Packwerk, RuboCop, Zeitwerk, Rails/route smoke checks, ERB/Ruby syntax, Tailwind, backlog integrity, and diff checks passed; PostgreSQL denial blocked the full and focused specs before examples.
