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
