# CitySocial — a modular-monolith social platform, agent-ready

One Rails app, one database, many near-full "apps" (**modules**) as mountable
engines under `components/`. Boundaries are enforced by Packwerk; modules
communicate through an inspectable event bus. On top of the app sits a Claude
Code workflow layer that takes ideas → scoped specs → implementation → a verified
green build, and can run that loop autonomously.

## Run it

```bash
bundle install
cp .env.example .env            # point at your Postgres + Redis
bin/rails db:create db:migrate
bin/rails server                # feed lives at /feed
```

(There is no `node`/JS build here — add Hotwire or a JSON API per your mobile plan.)

## Mine for robustness and performance bugs

Run the deterministic local fuzz suite against the test database:

```bash
bin/bug-mine
DEEP=1 bin/bug-mine             # longer campaign
FUZZ_SEED=71945213 bin/bug-mine # reproduce a failure
```

It combines property checks, malformed public requests with latency/SQL budgets,
and a stateful user-journey fuzzer. See `docs/bug-miner.md` for controls and
failure triage.

## Architecture in one breath

- `components/platform_core` — the shared kernel: `User`, the `Follow` social
  graph, the public `PlatformCore::Graph` API, and `PlatformCore::EventBus`.
  Depends on nothing.
- `components/feed` — the **reference module**. Copy its shape.
- The module contract (depend only on the kernel; cross boundaries only via
  events or `app/public`) is spelled out in `CLAUDE.md` and enforced by
  `bundle exec packwerk check`.

## Add a new app in one command

```bash
bin/rails g app_module marketplace      # scaffolds the engine, wires Gemfile + routes
bundle install && bin/rails db:migrate
```

## The agent workflow

`CLAUDE.md` (root) + each module's nested `CLAUDE.md` are auto-loaded by Claude
Code as memory. The workflows live in `.claude/commands/` as slash commands:

| Command | What it does |
|---|---|
| `/scope-idea <idea>` | Idea → bounded, conventions-checked spec (stops for approval) |
| `/new-app-module <name> — <purpose>` | Runs the generator, scopes the MVP |
| `/implement-feature <spec>` | Builds inside one module, then verifies |
| `/babysit` | Runs verify→fix until the build is green |
| `/update-memory` | Folds lessons into CLAUDE.md / docs/lessons.md |
| `/build-from-vision <vision>` | Big vision → phased, module-by-module roadmap |

### The loop (run automatically)

The verification gate is `bin/verify` (rspec + packwerk + rubocop). The
autonomous loop is `bin/loop`, which runs a command headlessly with `claude -p`
and repeats until `bin/verify` is green:

```bash
bin/loop babysit                         # self-heal until green
MAX=8 bin/loop "implement-feature docs/specs/events.md"
```

There is no built-in time-based `/loop` in Claude Code — `bin/loop` is the real,
inspectable mechanism (a shell loop over headless runs gated on `bin/verify`).
For scheduled runs, drive `bin/loop` from cron or CI.

The autonomous product routines read `northstar.md` on every run. That file is
the long-form, durable description of the product's intended destination: it
guides research and relative feature impact, while concrete work still requires
Dane's idea inbox, verified research, or repository evidence.

### A note on commands vs. skills

`.claude/commands/*.md` is the well-supported custom-command format used here.
Claude Code now also supports `.claude/skills/<name>/SKILL.md`, which gives the
same `/name` invocation **plus** autonomous triggering (the agent can choose to
run it). If you want, say, `/babysit` to fire on its own when it notices a red
build, graduate these files to skills — the prompt bodies port over unchanged.

## Why the event bus matters beyond this app

`PlatformCore::EventBus.registry` is a live map of every event and its handlers.
That makes the system's wiring introspectable — the natural seam for exposing
module capabilities to external tooling or an agent registry later.
