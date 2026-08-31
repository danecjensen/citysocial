# Making CitySocial Self-Evolving

A review of this codebase against the Shelley Test — the nine criteria for
agent-ready software from ["Revisiting Joel"](https://blog.exe.dev/revisiting-joel)
— plus a concrete roadmap for closing the one gap that matters most: taking a
**general, abstract human directive all the way to production without a human in
the middle of every step**.

The benchmark directive used throughout this document:

> "Use the NewsBlur CLI or API in my account (already focused on Austin news) to
> pick news articles every day to show on the feed. Pick articles I'd be
> interested in. Build a brief taste profile of my taste. I can give you example
> articles in the past that I have liked."

Today's system would **stall** on that directive at four specific points,
documented below. Each has a bounded fix.

---

## Part 1 — Where the system already stands (the honest scorecard)

CitySocial already has a real agentic substrate, not aspirations: two scheduled
autonomous routines (`feature-loop` 4×/day, `feature-research` daily), a human
idea inbox (`DanesIdeas.md`) with a strict marking protocol, a scored backlog
(`routines/backlog.json`), a three-agent research fleet with a decorrelated-model
grader, git-tracked compounding memory (`progress.md` Codebase Patterns,
`docs/lessons.md`), a machine-enforced architecture contract (Packwerk), one
verification gate (`bin/verify`), and an authenticated write API
(`docs/ingestion_api.md`) already fed by an external discovery routine (ATX
events). Scored against the Shelley Test:

| # | Criterion | Grade | One-line state |
|---|---|---|---|
| 1 | Agentic code review | ✗ | Routines open draft PRs; only Dane reviews. No adversarial second model. |
| 2 | Continuous deployment w/ LLM supervision | ✗ | Heroku deploys exist; nothing watches a release and nothing can halt one. |
| 3 | End-to-end integration tests | ◐ | Strong request specs; no browser-level smoke suite of the core loops. |
| 4 | Observable systems for agents | ◐ | Sentry/PostHog/Papertrail exist and `docs/operations.md` even writes the agent workflow — but no routine actually consumes production telemetry. |
| 5 | Access to latest models | ✓ | Grader deliberately runs a different model; SETUP.md treats model choice as a lever. |
| 6 | Fast merge queues | ✗ | **There is no CI at all** (`.github/workflows` does not exist). `bin/verify` runs only inside routine containers; merges are gated by nothing but Dane's eyeballs. |
| 7 | Easy tool/agent provisioning | ◐ | `app_module` generator + `.claude/agents/` are excellent; there is no equivalent generator for *routines*. |
| 8 | Regular workflow discussion | ◐ | `progress.md` patterns + `lessons.md` compound, but the routine files themselves never evolve — the product self-improves, the *process* does not. |
| 9 | Agent-legible product | ◐ | Write API with tokens, idempotency, and docs is genuinely good. It is write-only: an agent cannot read back what happened to its own contributions. |

### Per-criterion fixes (smallest first)

**#6 — CI before anything else.** Everything downstream (agentic review,
auto-merge, deploy supervision) requires a machine-checkable green signal on the
PR itself. Add `.github/workflows/verify.yml` that runs `bin/verify` (Postgres
service container, gem cache, Tailwind build — the exact recipe is already
debugged in `progress.md` Codebase Patterns). Target under 5 minutes with
caching. Until this exists, "the loop closes on `bin/verify`" is only true
inside a single agent's container; a merge can still land red.

**#1 — Adversarial review routine.** A third scheduled routine
(`.claude/routines/pr-review.md`, different model than the implementer) that
lists open `claude/*` PRs, reviews the diff against acceptance criteria +
CLAUDE.md contracts, and posts findings as PR review comments. Then a tiered
merge policy, stated in the routine file: PRs that are (a) CI-green, (b)
reviewer-approved, and (c) entirely outside the hard walls (no migrations, no
auth, no deps, no config) may be merged by the reviewer routine itself;
everything else waits for Dane. This directly attacks the system's actual
bottleneck — the 6-open-PR circuit breaker trips because human merge latency,
not agent throughput, is the constraint.

**#2 — Deploy watchdog.** A post-deploy routine (or the same reviewer routine,
after merging) that waits one deploy cycle, then queries Sentry (hosted MCP at
`mcp.sentry.dev/mcp`, read-only scope — `docs/operations.md` §AI-agent workflow
already specifies this) for new/regressed issues tagged with the released SHA,
and PostHog for step-changes in the core engagement events. On regression: open
a revert PR and notify. Start report-only; graduate to auto-revert once trusted.

**#3 — A five-path browser smoke suite.** Playwright is already proven to work
in routine containers (documented in `progress.md`). One system spec per core
loop (signup → post → timeline; join community → comment; list item → message
seller; RSVP; notification badge). Keep it under a minute; wire into
`bin/verify` behind a flag and into CI unconditionally.

**#4 — Give the routines eyes on production.** `feature-loop` Phase 1b lists
"errors from a connected logging service" as valid evidence, but no connector is
attached. Attach the Sentry MCP (read-only) to both routines' claude.ai/code
configuration. Add one PostHog query recipe to `docs/analytics.md` ("how a
routine fetches the 14-day trend for event X") so `impact` scores and PR bodies
can cite real baselines instead of guesses. This turns the backlog's `impact`
field from a vibe into a measurement.

**#7 — A routine generator.** See Part 3 — this is load-bearing for the
NewsBlur class of request.

**#8 — Let the process evolve itself.** Everything under `.claude/routines/` is
currently human-edited only. Add a weekly retro routine that reads the last ~28
`progress.md` run entries and PR outcomes (merged? reverted? how many review
rounds?), and opens a PR **editing the routine files themselves** — tightening a
phase that keeps failing, raising a threshold that admits slop, pruning a dead
evidence source. The `.claude/` write-approval problem documented in
`lessons.md` doesn't apply: these edits ship as ordinary PRs for Dane to merge,
which is exactly the right human gate for process changes. This is the
difference between a system that improves its product and a system that
improves *itself*.

**#9 — Read API + `llms.txt`.** Covered in Part 3 (the taste loop needs it).
Also: serve `/llms.txt` describing the product surface, the API, and where the
docs live, so third-party agents (including future instances of this system)
can operate the product as users — the blog's point that an agent-illegible
product loses to a legible one.

---

## Part 2 — The real gap: abstract directive → production

Run the NewsBlur directive through today's pipeline and watch where it dies:

1. Dane drops the sentence into `DanesIdeas.md` `## Inbox`. ✓ (intake works)
2. `feature-loop` 1a triages it. The idea implies **at least five distinct
   deliverables** (NewsBlur integration, a daily sourcing routine, a taste
   profile, feed surfacing, a feedback loop). The routine must either tag it
   `rejected: too vague` or split it — but its splitting guidance assumes
   sibling *items*, not a phased *program* with dependencies. **Stall #1: no
   decomposition layer between "idea" and "backlog item."**
3. Even split, the first item needs NewsBlur credentials and possibly a
   dependency. Phase 3 hard walls (secrets, new deps) block it →
   `blocked: needs-human-approval`, forever. **Stall #2: hard walls are binary;
   there is no protocol for a human to unlock a *specific, scoped* exception.**
4. The daily picker itself is not code in this repo at all — it is a *new
   scheduled routine*. Creating routines is a manual claude.ai/code UI flow
   documented in SETUP.md. **Stall #3: the system cannot provision new
   routines, and has no template for "sourcing" routines** (the ATX events
   routine — the perfect precedent — lives outside the repo entirely; only its
   output contract survives in `docs/ingestion_api.md`).
5. "Pick articles I'd be interested in" requires knowing which past picks Dane
   engaged with. The API is write-only. **Stall #4: no read-back, so a taste
   loop cannot close.**

### Fix for Stall #1 — the Mission layer

Add `routines/missions/` (repo root, beside `backlog.json`, for the same
`.claude/`-write-approval reason recorded in `lessons.md`). A **mission** is a
git-tracked markdown file: the directive verbatim, a phased decomposition into
ordinary backlog items with dependencies, the human-unlock checklist (Stall #2),
and a status ledger.

Wire it into `feature-loop` 1a with one new triage branch: an idea too big for
one item but concrete enough to decompose gets tagged
`` `[M-001 mission]` `` and spawns a mission file — effectively running the
existing `/build-from-vision` command's logic autonomously, at intake time.
Phase 1 then feeds the backlog from missions: whenever a mission's next
unblocked phase has no live item, emit it (`origin: "mission"`, evidence =
mission file + phase). Phase 2 scoring needs nothing new; `northstar_fit` for
mission items cites the directive, which is human intent and therefore already
grounded. The mission file's status ledger gives Dane one page per big idea
showing exactly how far his sentence has traveled — today that visibility
doesn't exist anywhere.

### Fix for Stall #2 — scoped unlocks instead of binary walls

Keep every hard wall as the default. Add one escape hatch, in the mission file:

```markdown
## Unlocks (human-edited only)
- [x] ENV: NEWSBLUR_USERNAME, NEWSBLUR_PASSWORD may be referenced (never read
      into the repo); Dane sets them in Heroku + routine env.  — Dane, 2026-09-02
- [ ] DEP: `newsblur` gem — NOT granted; use the plain HTTP API instead.
```

The routine may act on a checked unlock **only** for work inside that mission,
and the unlock names the wall it opens (`ENV:`, `DEP:`, `MIGRATION:`,
`ROUTINE:`). Unchecked = blocked, as today. The routine writes *requests* for
unlocks (unchecked boxes with rationale); only Dane checks them. This converts
"blocked: needs-human-approval" from a dead end into a queue Dane can drain
from his phone in the GitHub app — the same interaction model as
`DanesIdeas.md`, which is the system's best-proven UX.

Enforcement note: unlock lines are an instruction channel into an autonomous
agent, so the retro routine should periodically verify that mission files only
ever gain unlock checkmarks via commits authored by Dane, and `pr-review.md`
should treat any agent-authored edit to an `## Unlocks` block as an automatic
review failure.

### Fix for Stall #3 — sourcing routines as first-class, generated citizens

This is the "definitely needs to be able to create routines that source
information from the internet" requirement, and the repo already contains 70%
of the pattern — it's just not reified:

- The **output contract** exists: `POST /api/v1/posts` and `/api/v1/events`
  with per-producer tokens, `external_id` idempotency, and retry-safe semantics
  (`docs/ingestion_api.md`). `Feed::PublishPost` already accepts `source`,
  `title`, `url`, `body` — a news pick needs zero new write-path code.
- The **precedent** exists: the ATX events discovery routine (external fetch →
  curation with `score`/`why` → API post → module renders top-N). But it lives
  outside the repo, so nothing can copy, review, or evolve it.

Reify the pattern:

1. **`.claude/routines/sources/<name>.md`** — sourcing routines live in the
   repo like `feature-loop.md` does, so they are versioned, reviewable by the
   PR-review routine, and evolvable by the retro routine. Repatriate the ATX
   events routine here as the reference implementation.
2. **A template + generator.** `.claude/routines/sources/TEMPLATE.md` with the
   fixed skeleton every sourcing routine shares: Phase 0 orient (read your
   taste/config file), fetch budget and allowed domains, curation criteria,
   idempotent POST via the ingestion API, self-grading (Part 3), and an
   append-only run log. A `/new-source-routine <name> <purpose>` command (mirroring
   `/new-app-module`) instantiates it. Now "create a routine that sources X
   from the internet" is a *bounded, one-item task the feature loop can do*.
3. **Provisioning protocol.** The one step an agent cannot do is grant the
   schedule. Make it a standard mission unlock:
   `ROUTINE: create claude.ai/code routine "news-picker", prompt "Read
   .claude/routines/sources/news-picker.md and follow it exactly.", daily 06:30,
   env: NEWSBLUR_*` — a copy-paste instruction for Dane, identical in spirit to
   SETUP.md §4. Where the environment exposes a trigger-creation tool, the
   routine may instead create the trigger itself and record the trigger ID in
   the mission file; the unlock checkbox remains the authorization either way.

### Fix for Stall #4 — close the taste loop (read-back API)

Add the minimal read surface that lets a producer grade its own output:

- `GET /api/v1/posts?source=<token's source>&since=<date>` → for each of that
  producer's own posts: `external_id`, and content-free engagement counts
  (likes, comments, saves, detail-page views if available). Same bearer-token
  auth; a token can read **only its own source's** posts, which keeps this
  inside the existing privacy posture (counts only — never who, never text —
  consistent with the `docs/analytics.md` contract).

That single endpoint converts every sourcing routine from open-loop to
closed-loop, and it is the repo's first step toward Shelley #9's real meaning:
agents as *users* of the product, not just contributors to it.

---

## Part 3 — The NewsBlur mission, end to end (the worked example)

What the finished pipeline looks like once Parts 1–2 land. This is the
acceptance test for the whole roadmap: if this flow works, the system has
become self-evolving in the sense Dane asked for.

**Day 0 — intake.** Dane pastes the directive into `DanesIdeas.md`. The next
`feature-loop` run recognizes it as mission-sized, writes
`routines/missions/M-001-newsblur-daily-picks.md` with this decomposition, tags
the inbox line `` `[M-001 mission]` ``, and files unlock requests:

- *Phase A (no unlocks needed):* `routines/taste/news.md` — the taste profile
  file: `## Liked examples` (Dane pastes URLs of past articles he liked — this
  is the "I can give you example articles" channel, same append-only ergonomics
  as `DanesIdeas.md`), `## Inferred profile` (routine-maintained: topics,
  sources, formats, negative signals, each line citing the evidence that put it
  there), `## Pick log` (append-only: date, picks, why, later-measured
  engagement).
- *Phase B (needs `ENV:` unlock):* write `.claude/routines/sources/news-picker.md`
  from the template: authenticate to NewsBlur's HTTP API with `NEWSBLUR_*` env
  vars, pull the Austin-focused river, score candidates against
  `routines/taste/news.md`, pick 3–5, POST each to `/api/v1/posts` with
  `source: "newsblur-picker"`, `external_id: "newsblur-story-<hash>"`, and a
  one-line "why picked" in the body (the events module already proved curation
  metadata like `why` earns its keep in the UI).
- *Phase C (needs `ROUTINE:` unlock):* provision the daily schedule; token
  issued per `docs/ingestion_api.md` (`PlatformCore::ApiTokens.issue!(source:
  "newsblur-picker", ...)`).
- *Phase D (ordinary backlog items):* the read-back endpoint from Part 2; any
  feed presentation polish for link posts (most already shipped in Home Feed
  2.0's rich news previews).
- *Phase E (self-tuning, no unlocks):* each picker run starts by reading
  yesterday's engagement via the read-back endpoint, appends outcomes to the
  pick log, and edits `## Inferred profile` — one-line changes with evidence,
  the same discipline as `progress.md` Codebase Patterns. New liked-examples
  from Dane always outrank inferred signals, mirroring how `DanesIdeas.md`
  outranks auto-proposals today.

**Day 1–3 — build.** Dane checks two unlock boxes from his phone and sets two
Heroku/routine env vars. `feature-loop` drains phases A→D as ordinary scored
items, one PR per run; the PR-review routine reviews each; CI gates each; the
auto-merge tier lands the ones outside the walls.

**Day 4 onward — steady state.** Every morning the picker reads Dane's taste
file, picks Austin stories, posts them to the feed with reasons, measures
yesterday's picks, and sharpens its own profile. The retro routine watches
whether pick engagement trends up and proposes edits to the picker's own
routine file when it doesn't. No human step remains except reading the feed —
and merging the PRs the system writes about itself.

Everything in this flow reuses a pattern the repo already trusts: idea inbox →
marking protocol, append-only logs, scored items, draft PRs, `bin/verify`,
token-authenticated idempotent ingestion. The mission layer, unlocks, sourcing
template, and read-back endpoint are the only genuinely new machinery.

---

## Part 4 — Build order

Each row is one bounded piece of work (most are single `feature-loop` items;
the routine `.md` files are cheapest of all — they are prose, not code).

| Seq | Deliverable | Unblocks |
|---|---|---|
| 1 | CI workflow running `bin/verify` on every PR | Shelley #6; everything below |
| 2 | Mission layer: `routines/missions/` convention + `feature-loop` 1a/1b amendments | Stall #1, #2 |
| 3 | Sourcing template + `/new-source-routine` command; repatriate ATX routine | Stall #3 |
| 4 | Read-back endpoint (`GET /api/v1/posts?source=…` with engagement counts) | Stall #4; Shelley #9 |
| 5 | `pr-review.md` reviewer routine + tiered auto-merge policy | Shelley #1; drains the PR queue |
| 6 | Attach Sentry MCP (read-only) + PostHog query recipe to routine configs | Shelley #4 |
| 7 | Retro routine that PRs edits to `.claude/routines/*.md` | Shelley #8; true self-evolution |
| 8 | Deploy watchdog (report-only first) | Shelley #2 |
| 9 | Browser smoke suite (5 core loops) | Shelley #3 |
| 10 | `/llms.txt` + API index | Shelley #9 |
| — | **M-001: NewsBlur daily picks** (Part 3) | The proof — runs on 1–6 |

Items 2, 3, 5, and 7 are routine-file prose changes plus small `feature-loop`
amendments — high leverage, near-zero code. Items 1, 4, 9, 10 are ordinary
bounded features that fit the existing module contract (the read-back endpoint
extends the kernel-owned ingestion API; nothing crosses a Packwerk boundary).

The deliberate design constraint throughout: **the human's job shrinks to
writing directives, checking unlock boxes, and merging PRs about the system
itself.** Every other step — decomposition, scoping, building, reviewing,
sourcing, measuring, and improving the process — belongs to the loop.
