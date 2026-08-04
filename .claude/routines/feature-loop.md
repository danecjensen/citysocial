# Feature Loop — Autonomous Routine

You are running unattended. No one will approve anything mid-run. Complete the full
cycle below, then stop. **One backlog item per run. Never more.**

Repo state: you have a fresh clone of the default branch. Nothing carries over from the
last run except what is committed to this repo. `backlog.json` and `progress.md` are your
only memory. `DanesIdeas.md` is Dane's human idea inbox — your highest-signal *input*.

## Files

All paths are relative to the repository root. Resolve them before Phase 0.

| Short name | Path |
|---|---|
| this file | `.claude/routines/feature-loop.md` |
| `backlog.json` | `.claude/routines/backlog.json` |
| `progress.md` | `.claude/routines/progress.md` |
| `research.md` | `.claude/routines/research.md` |
| `DanesIdeas.md` | `DanesIdeas.md` (repo root — Dane's idea inbox) |

If `progress.md` does not exist, create it with an empty `## Codebase Patterns` block.

---

## Phase 0 — Orient (always)

1. Read `backlog.json` and `progress.md` (read the `## Codebase Patterns` block first).
2. Run `git log --oneline -30` and `gh pr list --state open --author @me`.
3. Run the project's check command. If the default branch is **failing**, skip Phases 1–2
   entirely: fix the failure, open a PR, record it, and stop.

### Circuit breakers — check before doing anything else

Stop and post a summary instead of working if any of these is true:

- **6 or more open `claude/*` PRs.** The queue is backed up; more PRs make it worse.
- **The same item has failed 2 runs in a row.** Set its `status` to `blocked`, write why
  in `progress.md`, move on to the next item.
- **No item scores above the threshold** (see Phase 2), 1b is gated off, and step 1a
  found no new ideas in `DanesIdeas.md`.

---

## Phase 1 — Feed the backlog

Two sources feed the backlog. **Step 1a always runs; step 1b is gated.**

### 1a — Ingest Dane's ideas (ALWAYS — ignore the 1b gate)

`DanesIdeas.md` (repo root) is Dane's raw, human idea inbox — a stream-of-consciousness
to-do list he edits from the GitHub app. It is the **highest-signal input in the system**,
so it is processed on **every** run regardless of the 1b gate. Human ideas are grounded by
definition: Dane asking for it *is* the evidence, and desirability is already settled.

An idea is **unprocessed** iff it is a `- [ ]` line under the `## Inbox` heading with **no
trailing `` `[...]` `` tag**. (Lines in the instructions/legend above `## Inbox`, and any
already-tagged line, are never ingested.) For each unprocessed idea, in file order:

1. **Dedup.** Compare against `backlog.json` (any status), the open `claude/*` PRs from
   Phase 0, merged PR titles from the last 30 days, and already-tagged lines in
   `DanesIdeas.md`. On a match, tag the line `` `[dup F-0NN]` ``, check the box, and skip.
2. **Triage.** If the idea is unactionable — a Phase 3 hard wall, in `out_of_scope`, or too
   vague to become a concrete change — tag it `` `[rejected: <short reason>]` ``, check the
   box, and move on. Give a reason Dane can act on (e.g. `rejected: needs a specific screen`).
   Split an idea that implies several changes into multiple items; tag the source line with
   the first item's id and note the fan-out in `progress.md`.
3. **Accept.** Otherwise create a `backlog.json` item using the schema below with
   `origin: "danes-ideas"`, `status: "ready"`, `evidence` set to the **verbatim idea text**,
   and `confidence` starting at 0.8–0.9. Then tag the source line `` `[F-0NN queued]` `` and
   **leave the box unchecked** — an idea is only checked at a terminal state (see standard).

Commit `DanesIdeas.md` alongside `backlog.json`. **Never delete or reword Dane's text** —
only flip the checkbox and append/replace the one trailing `` `[...]` `` tag.

**The marking standard — the ONLY tags you may write (exactly one per line):**

| Line state | Meaning |
|---|---|
| `- [ ] idea` | pending — raw input, not yet seen |
| `` - [ ] idea `[F-0NN queued]` `` | accepted into the backlog, not started |
| `` - [ ] idea `[F-0NN blocked: <reason>]` `` | needs a human before it can proceed |
| `` - [x] idea `[F-0NN PR #<n>]` `` | built; draft PR opened (the loop's terminal state) |
| `` - [x] idea `[rejected: <reason>]` `` | won't do; reason given |
| `` - [x] idea `[dup F-0NN]` `` | already covered by an existing item/PR |

When an item advances (queued → PR opened, or → blocked), rewrite that line's tag in place
in the same run/branch that made the change (see Phase 4).

### 1b — Auto-propose (GATED: only if fewer than 5 items have `status: "ready"`)

Regenerating ideas on every run produces backlog churn, near-duplicates, and priority
thrash — the queue stops being stable enough to drain. **If 5+ items are already `ready`
(including anything 1a just added), skip 1b entirely and go to Phase 2.**

When the gate opens, propose **3–5** new items. Every proposal must be grounded in
something that exists in the repo or in connected data. Cite it in the `evidence` field.

**Valid evidence sources** (in rough priority order):

| Source | How to find it |
|---|---|
| Verified research briefs with `Status: fresh` | `## Briefs` in `research.md` (written by the feature-research routine) |
| Open GitHub issues, unlabeled or untriaged | `gh issue list --state open` |
| `TODO` / `FIXME` / `HACK` comments | `rg -n 'TODO\|FIXME\|HACK'` |
| README or docs promising something not implemented | diff docs against routes/handlers |
| Dead-end UX paths | routes/views with no link pointing to them; forms with no error state |
| Missing empty / loading / error states | components rendering collections with no zero-case |
| Errors from a connected logging or monitoring service | connector query |
| Test coverage gaps on business-critical paths | coverage report |
| Slow or N+1 queries visible in the code | ORM calls inside loops |
| Accessibility failures | missing labels, alt text, focus handling, contrast |

**Reject any idea you cannot tie to one of the above.** No "add dark mode," no "add
notifications," no "add CSV export" unless something in the repo actually asks for it.
An ungrounded idea is worse than an empty backlog because it consumes a whole run.
Research briefs are the one sanctioned path for outward-looking ideas — they arrive
already verified, graded, and cited, which is why they may enter the backlog and raw
"wouldn't it be nice" ideas may not.

**Consuming a research brief:** convert it to an item with `evidence` set to
`research.md#R-<id>` plus the brief's repo tie-in path, carry its `Acceptance sketch`
into `acceptance`, and set `confidence` no higher than `grader score / 10`. Then edit
that brief's `Status` line in `research.md` to `consumed (F-<id>)` — or
`rejected (<reason>)` if you decline it — so the research routine's queue drains.
That status line is the only part of `research.md` this routine may edit.

Before appending, check for duplicates against: existing `backlog.json` entries (any
status), merged PR titles from the last 30 days, and `progress.md`. If an idea overlaps
an existing item, strengthen that item's `evidence` instead of adding a new one.

### Item schema

```json
{
  "id": "F-041",
  "title": "Short imperative title",
  "problem": "One sentence: what is wrong or missing today.",
  "evidence": "app/views/sessions/new.html.erb:24 — form has no error branch",
  "acceptance": [
    "Concrete, checkable statement",
    "Another one"
  ],
  "impact": 4,
  "effort": 2,
  "confidence": 0.8,
  "score": 1.6,
  "status": "ready",
  "origin": "auto",
  "attempts": 0,
  "created": "2026-08-01",
  "pr": null
}
```

`status` is one of: `ready`, `in_progress`, `done`, `blocked`, `rejected`.
`origin` is one of: `auto` (proposed in 1b), `danes-ideas` (ingested from `DanesIdeas.md`
in 1a), `research` (consumed from a `research.md` brief). Items with
`origin: "danes-ideas"` must be kept in sync with their source line per the marking
standard (Phase 4, step 2).

---

## Phase 2 — Prioritize

Score every `ready` item: **`score = (impact × confidence) / effort`**

- `impact` 1–5: how much this improves the product for a real user.
- `effort` 1–5: 1 = under 50 lines, 5 = multi-day. **Anything above 3 gets split, not
  scheduled.** If it cannot be split, mark it `blocked` with reason `needs-human-scoping`.
- `confidence` 0.5–1.0: how sure you are the change is correct and wanted.

Rewrite the `score` field for every item, then pick the single highest scorer with
`score >= 1.0`. Ties break toward smaller `effort`. Set it to `in_progress` and increment
`attempts`.

If nothing clears 1.0, do not force it. Record that and stop.

---

## Phase 3 — Implement (exactly one item)

1. Branch: `claude/f-<id>-<slug>` off the default branch.
2. Implement the item and nothing else. No drive-by refactors, no dependency bumps, no
   reformatting untouched files.
3. Write or extend tests covering each `acceptance` line.
4. Run the full check suite. If it fails and you cannot fix it in this run, revert the
   branch, set `status` back to `ready`, record the failure, and stop.
5. Commit: `feat(F-041): short imperative title`
6. Open a **draft** PR. Body must contain:
   - the `problem` and `evidence` verbatim
   - the acceptance list as checkboxes
   - what you did *not* do and why
   - screenshots for any UI change

### Never touch without a human

Treat these as hard walls. If an item requires one, mark it `blocked` with reason
`needs-human-approval` and pick the next item:

- Database schema migrations, destructive or otherwise
- Authentication, authorization, session, or password handling
- Payment, billing, or subscription logic
- Secrets, credentials, environment config, `.env` files
- CI/CD, deploy configuration, infrastructure-as-code
- Adding a new third-party dependency
- Deleting user-facing functionality
- Anything touching PII beyond what already exists

---

## Phase 4 — Record (always, even on failure)

1. Update `backlog.json`: set the item's `status` and `pr` fields. Keep the file sorted by
   `score` descending.
2. **Sync `DanesIdeas.md` for `origin: "danes-ideas"` items** (skip otherwise). Map the
   item's new backlog state to the marking standard and rewrite that idea's line in place
   (never touch Dane's wording): opened a PR → `` - [x] … `[F-0NN PR #<n>]` ``; still
   `ready`/`in_progress` → `` - [ ] … `[F-0NN queued]` ``; `blocked` → `` - [ ] …
   `[F-0NN blocked: <reason>]` ``; `rejected` → `` - [x] … `[rejected: <reason>]` ``.
3. **Append** to `progress.md` — never overwrite:

```
## 2026-08-01 14:03 — F-041
Outcome: shipped | failed | blocked | skipped
PR: <url or none>
Changed: path/one.rb, path/two.tsx
Notes: one or two lines on what actually happened
Learnings:
- <only if genuinely reusable>
```

4. If you learned something that applies to *future* work rather than this one item,
   promote it to the `## Codebase Patterns` block at the top of `progress.md`. Keep that
   block under 20 lines — prune the least useful line when you add one. It is read at the
   start of every run and it is the only thing that compounds.
5. Commit `backlog.json`, `progress.md`, and any `DanesIdeas.md` changes on the same branch
   as the change. If the run produced no code (e.g. a run that only ingested ideas in 1a),
   commit them straight to a `claude/backlog-<date>` branch.

---

## Stop condition

After Phase 4, stop. Do not start a second item. Do not "keep going while you're here."
The next run in ~6 hours will pick up the next item with a clean context, which is the
entire point of the design.
