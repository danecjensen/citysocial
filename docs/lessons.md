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
- OAuth/OmniAuth belongs in platform_core (identity is kernel-owned): register the
  Rack strategy in the engine's own initializer via `app.middleware.use
  OmniAuth::Builder`, not in a host `config/initializers` file. Missing ENV
  credentials only fail at request time, so boot stays green without them.
- OmniAuth request phase must be a CSRF-protected POST: render the "Continue with
  Google" control with `button_to` (ButtonComponent href+method: :post) so Rails
  injects the authenticity token that omniauth-rails_csrf_protection verifies. A
  plain GET link is rejected by OmniAuth 2.
- Test OmniAuth without the network: set `OmniAuth.config.test_mode = true` and
  `OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(...)`, then GET
  the callback path directly; reset both in an ensure/after block so the mock does
  not leak into other request specs (the middleware runs on every request).
- Linking a Google login to an existing account trusts the provider's verified
  email. CitySocial does not verify password-account emails, so before adding a
  second provider or an email/password-reset flow, add email verification to avoid
  an unverified-email account-takeover path.
- Before merging a stacked PR chain, rebuild each branch from only its own commits,
  scan the assembled tree for conflict markers, parse shared state files, and run
  `bin/verify`; a GitHub-mergeable stack can still contain committed conflict debris.
- Generate Active Storage URLs inside engine ViewComponents through
  `helpers.main_app.rails_blob_path`; polymorphic `image_tag` routing can otherwise
  prefix blob paths with the engine mount and produce persistent 404s.
- When a page renders the SAME `form_with` scope more than once (an "add" form plus
  a per-row "edit" form for every record), pass a unique `namespace:` to each form.
  Without it every form emits identical DOM ids (`restaurant_photos`, ...), and a
  `<label for=...>` then resolves to the FIRST matching input on the page — so a
  file chosen in a row's "Add photos" field lands in the top add-form and the row's
  save uploads nothing. Namespacing changes ids only; the submitted param names
  stay on the shared scope, so controllers are unaffected. Give repeated hidden
  fields `id: nil` too so they don't re-introduce the duplicate.
- Rails 7.2 connection-pool `new_connection` only allocates a lazy adapter; call
  `connect!` before recording physical-connect timing, or the expensive libpq
  handshake and PostgreSQL type-map setup are misreported as query time.
