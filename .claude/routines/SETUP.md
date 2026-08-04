# Setup

Everything lives under `.claude/routines/` so nothing in this bundle collides with files
already at your repo root.

## 1. Get the files into the repo

**Preferred — locally, then push:**

```bash
cd /path/to/your-repo
unzip ~/Downloads/feature-loop.zip -d .
git add .claude/routines
git commit -m "chore: add feature-loop routine"
git push
```

**If you must use github.com:** drag-and-drop upload will silently drop the `.claude`
folder, since browsers hide dot-prefixed directories. Instead use **Add file → Create new
file** and type the full path `.claude/routines/feature-loop.md` into the filename box —
GitHub creates the directories from the path. Repeat for each file.

## 2. Fill in the three required fields in `backlog.json`

The routine is only as good as these. Nothing else needs editing.

- **`product_context`** — a real paragraph, not a sentence. What the app is, who uses it,
  what "better" means for them. This is what stops the routine from proposing dark mode
  and CSV export.
- **`check_command`** — the exact command that must pass before it commits.
- **`out_of_scope`** — anything you don't want touched, on top of the hard walls already
  in Phase 3.

Delete the `F-001` example item once you've read it.

## 3. Create the routine

At `claude.ai/code/routines` → **New routine** → **Remote**.

Connect the repository. Then set the prompt to exactly this — one line, so all the real
logic stays version-controlled and you iterate on it with git rather than a web form:

```
Read .claude/routines/feature-loop.md and follow it exactly.
```

**Trigger:** Schedule. Presets top out at daily, so pick daily first, then set a custom
cron with `/schedule update` from the CLI:

```
7 6,12,18,23 * * *
```

Four runs a day, offset seven minutes off the hour so you're not landing in the
top-of-hour crowd. Times are your local timezone.

**Permissions:** leave "Allow unrestricted branch pushes" **off**. The routine is designed
to open draft PRs on `claude/*` branches and never touch your default branch. Turning this
on removes the only thing standing between an unattended agent and your main branch.

**Connectors:** all of your connected connectors get attached by default. Remove every one
this routine doesn't need. If it should read your error logs or issue tracker for Phase 1
evidence, keep those and drop the rest.

**Model:** worth being deliberate. The implementation phase benefits from a stronger
model; if cost becomes the issue, the lever is cadence before model.

## 4. Run it once manually before trusting the schedule

Trigger a manual run and read the resulting PR closely. The first run tells you more than
any amount of prompt tuning. Specifically check:

- Did Phase 1 cite real file paths in `evidence`, or invent plausible-sounding ones?
- Is the PR scoped to one thing, or did it drive-by refactor?
- Did `progress.md` get a useful learning, or boilerplate?

If evidence quality is poor, the fix is almost always a thinner `product_context`, not a
longer routine file.

## After a week

Watch for two things:

- **PRs piling up unreviewed.** The circuit breaker halts at 6 open `claude/*` PRs, which
  means the loop stops producing until you clear the queue. That's intentional. If you're
  consistently hitting it, drop to 2 runs a day.
- **Backlog churn.** If priorities keep reshuffling and items never drain, split this into
  two routines: one daily that runs Phase 1 only, one 4×/day that skips Phase 1 entirely.
