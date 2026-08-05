# Feature Research — Autonomous Routine

You are running unattended. No one will approve anything mid-run. Complete one full
research cycle below, then stop. **This routine produces research briefs, never code.**
The feature-loop routine (`.claude/routines/feature-loop.md`) consumes your briefs as
evidence when it replenishes its backlog — you are its eyes on the outside world.

Repo state: fresh clone of the default branch. Nothing carries over between runs except
what is committed. `research.md` is your only memory.

## Files

All paths relative to the repository root.

| Short name | Path | Access |
|---|---|---|
| this file | `.claude/routines/feature-research.md` | read |
| `research.md` | `routines/research.md` | read + append |
| `backlog.json` | `routines/backlog.json` | **read-only** — feature-loop owns it |
| `progress.md` | `routines/progress.md` | append a run entry only |

## The stack (tool ladder)

Use the best tool available, falling back down the ladder:

| Job | First choice | Fallback |
|---|---|---|
| Deep / semantic search | Exa (if an Exa MCP tool is connected) | `WebSearch` |
| Specific page → clean markdown | Firecrawl (if a Firecrawl MCP tool is connected) | `WebFetch` |
| "Current best way to do X" | either of the above **scoped to the last 30 days** | — |

**The last-30-days rule:** any claim about current best practice, product trends, or
"what works now" must be backed by a source from the last 30 days. Evidence of *user
demand* (complaints, feature requests, forum threads) may be older — demand ages well,
technique advice does not.

**Citation rule:** never write a URL into `research.md` that was not successfully
fetched during this run.

---

## Phase 0 — Orient

1. Read `research.md` — the `## Standing Questions` block first, then skim recent briefs.
2. Read `backlog.json`: `product_context`, `out_of_scope`, and existing item titles.
3. Run `git log --oneline -30` and skim merged/open `claude/*` PR titles
   (`gh pr list --state all --limit 30`) so you don't re-research what's shipped.

### Circuit breakers — check before doing anything else

Stop and record a skipped run instead of working if any of these is true:

- **4 or more briefs in `research.md` have `Status: fresh`.** The queue is full;
  feature-loop hasn't consumed them yet. More research now is churn.
- **The last 2 research runs both produced zero passing briefs.** Something is wrong
  with the questions, not the effort. Rewrite `## Standing Questions` with a note about
  what kept failing, record the run, and stop.

---

## Phase 1 — Draft the research plan

Write (in working memory, not the file) **3–5 research questions**, each with an initial
keyword set of 4–8 terms. Ground every question in one of:

- a `## Standing Questions` entry from `research.md`
- a specific module that exists today (feed, communities, marketplace, restaurants,
  events) and its engagement loop
- a gap the product context names (loops that don't close, states that are missing)

Good question shape: *"What do Austin residents complain is missing when they try to
sell locally on Facebook Marketplace / Craigslist?"* — a persona, a job, a place where
real people talk about it.

Bad question shape: *"What features do social apps have?"* — no persona, no job,
guaranteed slop. Reject your own question if it reads like this.

---

## Phase 2 — Run it once (the scout fleet)

Launch one **research-scout** agent per question, in parallel, passing the question and
its keyword set verbatim. If the Agent tool or the agent type is unavailable in this
environment, run the scout procedure yourself, one question at a time, following
`.claude/agents/research-scout.md`.

Collect all findings. Note each scout's `KEYWORDS THAT WORKED` / `PRODUCED SLOP` lines —
they feed reruns and the next run's Standing Questions.

---

## Phase 3 — The verification fleet

For each finding worth keeping (drop obvious duplicates first), launch one
**research-verifier** agent with the full finding and sources. Verifiers re-fetch
sources, check the repo for overlap, and enforce the module contract. Keep only
`VERIFIED` and `NARROWED` results.

**Fresh-keyword reruns:** if a question produced zero surviving findings but the topic
still seems real (e.g. sources existed but were too weak), rerun its scout **once** with
a fresh keyword set built from the `KEYWORDS THAT WORKED` lines and the verifier's cut
reasons. **Maximum one rerun per question. Never a third pass.**

---

## Phase 4 — Review, delete, redraft

This is the engineered part of the loop — do it deliberately:

1. **Review the outputs** as a set: do the survivors cluster on one module? Do any
   contradict each other or the product context?
2. **Delete what is useless.** A finding that survived verification can still be useless
   — too similar to a fresh brief, too thin to write acceptance criteria for. Delete it.
3. **Redraft around what is missing.** If deletion left a hole (a module or loop with no
   coverage this run and no fresh brief), draft ONE new question targeting the hole and
   run Phases 2–3 for it. **Maximum one redraft cycle per run.**

Then convert each survivor into a draft brief (schema below) with concrete acceptance
criteria a coding agent could check.

---

## Phase 5 — The last quality gate

Launch one **research-grader** agent with all draft briefs. It runs on a different model
with fresh context — that independence is the point; do not summarize your reasoning to
it, just hand it the briefs.

- **Score 7+:** the brief passes. Record it as `Status: fresh`.
- **Score 4–6:** apply the grader's `FIX` line **once** (strengthen the source, narrow
  the scope), resubmit only the fixed briefs for regrading. **One regrade round, total.**
  Still below 7 → cut.
- **Score 1–3:** cut immediately. Do not rework.

A run that ends with zero passing briefs is a valid outcome. Record it honestly.

---

## Phase 6 — Record (always, even on failure)

1. **Append** passing briefs to the `## Briefs` section of `research.md` using the
   schema below. Never edit or delete existing briefs — feature-loop marks them
   `consumed` itself.
2. Update `## Standing Questions` (top of `research.md`): add questions worth re-asking,
   remove ones that are answered or repeatedly produce slop. **Hard cap: 10 lines.**
3. Append a run entry to `progress.md` under `## Runs`:

```
## 2026-08-04 06:07 — research
Outcome: produced N briefs | zero-brief run | skipped (<breaker>)
Briefs: R-014, R-015
Cut: 7 findings (3 unverifiable sources, 2 already built, 2 failed grading)
Notes: one or two lines
```

4. Commit `research.md` + `progress.md` to branch `claude/research-<YYYY-MM-DD>` and
   open a **draft PR** titled `research: <date> — <N> briefs`. Body: the new briefs
   verbatim plus one paragraph on what was cut and why. Never push to the default branch.

### Brief schema (in `research.md`)

```markdown
### R-014 — Short imperative feature title
- Date: 2026-08-04
- Module: communities
- Demand signal: one sentence — who is asking, where, for what.
- Sources:
  - https://... — one line on what it supports (fetched 2026-08-04)
- Repo tie-in: components/communities/app/models/communities/post.rb — what exists that this extends
- Acceptance sketch:
  - Concrete, checkable statement
  - Another one
- Grader score: 8/10
- Status: fresh
```

`Status` is one of: `fresh` (awaiting feature-loop), `consumed (F-xxx)` (feature-loop
converted it), `rejected (<reason>)` (feature-loop declined it). Only feature-loop
changes a brief's status.

IDs are `R-` + the next number after the highest existing brief ID.

---

## Hard limits

- Max **6 passing briefs** per run — past that, you are flooding the queue.
- Max ~40 web fetches/searches per run — past that, the plan was too broad; stop and
  record what you have.
- Never propose anything touching `out_of_scope` or feature-loop's Phase 3 hard walls
  (migrations, auth, payments, new dependencies, new modules). The verifier and grader
  both check this; if it somehow survives them, this is your last chance to cut it.

## Stop condition

After Phase 6, stop. Do not start implementing any brief — that is feature-loop's job,
in its own run, with its own prioritization. The separation is the design.
