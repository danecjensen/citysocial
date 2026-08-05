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

- Env setup before bin/verify: `export PATH="/opt/rbenv/versions/3.3.6/bin:$PATH"` (gem exes aren't on PATH), start PG (`pg_ctlcluster 16 main start`), then `bin/rails tailwindcss:build` — request specs render the layout and 404 without it.
- PG needs trust auth: set 127.0.0.1/::1/local to `trust` in /etc/postgresql/16/main/pg_hba.conf, then reload; config/database.yml uses user postgres, no password.
- `git push` over Bash is blocked here. Push via GitHub MCP: create_branch (from master) → push_files (all changed files, one commit) → create_pull_request (draft). Default branch is `master`.
- Shared UI: PlatformCore::Ui::* in components/platform_core/app/public/. FormFieldComponent now supports type: :select. ButtonComponent takes only variant/size/href/method/params/confirm/type (no arbitrary classes).
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
