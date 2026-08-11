# Lessons (git-tracked agent memory)

Append one imperative rule per line as you learn them. Promote universal ones
into CLAUDE.md.

- Fix packwerk violations at the boundary (event or app/public API); never add a
  sibling dependency to package.yml to silence the checker.
- Tailwind v4 purges any class it cannot see verbatim: keep variant->class maps
  as complete literal strings in components, and keep the `.rb` `@source` glob
  for app/public in application.css — it is load-bearing.
- The tailwindcss:install generator cannot insert tags into a minimal layout
  head; verify stylesheet_link_tag "tailwind" exists after running it.
- Run the puma dev server with WEB_CONCURRENCY=0 on macOS; forked workers crash
  on objc fork-safety (NSCharacterSet + fork).
- The app_module generator historically omitted the `<name>.append_migrations`
  initializer, so a new engine's db/migrate is invisible to host `db:migrate`
  (silent no-op, then PG::UndefinedTable). Fixed in engine.tt; verify the
  initializer exists in any hand-checked engine.rb before migrating.
- The generator names every module's wiring module `Events` (e.g.
  `Marketplace::Events`). If a module is itself named `events`, that produces
  `Events::Events`, which SHADOWS the top-level `Events` for all code lexically
  inside `module Events` — plain `Events::Event` then resolves to
  `Events::Events::Event` and blows up. Fix: rename the wiring module (we use
  `Events::Wiring`) rather than fully-qualifying every reference with `::`.
- Never keep files an unattended routine WRITES under `.claude/`: Claude guards its own
  config directory, so every Edit/Write there forces an approval prompt even when
  `Edit`/`Write` are allowlisted (neither the `allow` list nor the trigger's allowed-tools
  overrides it). Feature-loop/-research state lives at the repo-root `routines/` dir for
  this reason; read-only instruction files can stay in `.claude/routines/`.
- Validate user-supplied context links before rendering them: allow internal paths and
  explicit HTTP(S) URLs, and reject protocol-relative or executable schemes.
- For internal-only links, reject backslashes and control characters as well as `//`;
  browsers can normalize a leading backslash into a host-changing URL.
- After running `app_module`, sort its injected Gemfile entry and freeze the generated
  VERSION constant; the current generator templates need both cleanups for RuboCop.
- Parse `routines/backlog.json` after merging concurrent automation branches; resolving
  overlapping `next_id` and `items` blocks by concatenation can silently corrupt the queue.
- When concurrent module PRs conflict in shared registries, keep every module entry,
  regenerate Gemfile.lock and db/schema.rb, and parse-check routines/backlog.json;
  choosing one side can silently drop a module or commit invalid generated state.
- Before merging a stacked PR chain, rebuild each branch from only its own commits,
  scan the assembled tree for conflict markers, parse shared state files, and run
  `bin/verify`; a GitHub-mergeable stack can still contain committed conflict debris.
- Generate Active Storage URLs inside engine ViewComponents through
  `helpers.main_app.rails_blob_path`; polymorphic `image_tag` routing can otherwise
  prefix blob paths with the engine mount and produce persistent 404s.
