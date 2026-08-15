# Production operations

## Observability ownership

- PostHog owns product analytics, privacy-masked session replay, and future
  experiments. See `docs/analytics.md` for setup and the event contract.
- Sentry owns exceptions and performance. PostHog's Rails exception, ActiveJob,
  and log forwarding integrations intentionally remain disabled to prevent
  duplicate telemetry and spend.

PostHog is enabled in production only when `POSTHOG_PROJECT_TOKEN` is present.
Delivery is asynchronous and capture errors are warnings; analytics failure must
never fail a resident request. Search for `event=posthog_delivery_failed` and
`event=posthog_capture_failed` when validating delivery.

## Database connection latency

The connection-pool instrumentation emits structured warning logs only when a
checkout takes at least 100 ms, a new physical connection takes at least 250 ms,
or either operation fails. Override the thresholds with `DB_CHECKOUT_WARN_MS` and
`DB_CONNECT_WARN_MS` when tuning an environment.

- `event=database_connection_checkout` with high `busy`/`waiting` indicates pool
  contention.
- `event=database_connection_connect` indicates slow physical connection setup;
  compare its timestamp with Heroku runtime metrics and Postgres/platform events.
- A slow checkout and connect at the same timestamp usually means connection
  creation accounts for the checkout delay rather than pool contention.

Production keeps established connections indefinitely (`idle_timeout: 0`) and
warms the first connection when each Puma worker boots. libpq TCP keepalives
detect a dead path without reintroducing the recurring cold-connection penalty.

The probes use a monotonic clock and collect pool statistics only for slow or
failed operations, keeping the healthy request path and normal log volume small.

## Heroku logs and runtime metrics

The `citysocial-app` Heroku app has `log-runtime-metrics` enabled. Heroku emits
load and memory samples into Logplex approximately every 20 seconds. Papertrail
Fixa retains the application/platform stream up to 65 MB/day, with 7 days of
search and 365 days of archives (maximum $8/month). Use searches for
`database_connection_`, `sample#memory_`, Heroku router `service=`, and Heroku
error codes to correlate performance incidents before changing the database plan.

## Sentry

CitySocial uses the official Sentry Ruby 6.7 Rails and Sidekiq integrations plus
Vernier's multi-thread profiler. The integration captures every unhandled error,
sampled request/job traces, profiles relative to those traces, structured request,
job, and mailer logs, release health, slow-query source locations, queue time, and
trace-connected database connection metrics. Sentry remains a complement to the
complete Heroku/Papertrail stream, not its replacement.

### First production setup

1. Create one Sentry **Rails** project and copy its DSN into Heroku:
   `heroku config:set SENTRY_DSN=... -a citysocial-app`.
2. Keep `SENTRY_ENABLED_ENVIRONMENTS=production`. If a separately deployed
   staging environment uses the same project, add `staging` and give it an
   explicit `SENTRY_ENVIRONMENT=staging` value.
3. Enable Heroku runtime dyno metadata so the SDK can use the build commit as
   the release when a slug has no `.git` directory:
   `heroku labs:enable runtime-dyno-metadata -a citysocial-app`.
4. Deploy, then run
   `heroku run bin/rails sentry:smoke_test -a citysocial-app`. Search Sentry for
   `CitySocial Sentry smoke test`, verify its release/environment, then resolve
   the test issue.
5. In Sentry, enable the organization default data scrubbers and IP-address
   scrubbing as defense in depth. Add `body`, `bio`, `description`, `details`,
   `message`, `authorization`, and `token` to the server-side sensitive-field
   list too. Server rules protect telemetry from future SDKs and services, while
   the application-side rules protect data before it leaves the dyno.

No Sentry auth token belongs in the Rails runtime. `SENTRY_DSN` is the only
required application credential. Tokens used by CI, MCP clients, or humans must
be separately scoped and stored by those systems.

### Privacy and trace boundaries

- Authenticated residents are attached only as an opaque user ID. Names,
  handles, emails, IP addresses, cookies, query strings, request bodies, SQL
  binds, frame locals, and Sidekiq arguments are not sent.
- Rails parameter filtering also redacts resident-authored long text from
  traces and ordinary Rails logs. Public record IDs, controller/action names,
  module names, HTTP status, timings, and queue metadata remain available for
  diagnosis.
- Incoming distributed traces are continued only when their Sentry organization
  matches this project's organization. Outgoing HTTP trace headers are disabled
  until a downstream host is explicitly listed in
  `SENTRY_TRACE_PROPAGATION_TARGETS`.
- Do not turn on `SENTRY_DEBUG` in steady-state production; it is for diagnosing
  SDK delivery only and increases platform log volume.

### Sampling and cost controls

Errors are never sampled by this application. Performance telemetry defaults are:

| Setting | Default | Effect |
| --- | ---: | --- |
| `SENTRY_TRACES_SAMPLE_RATE` | `0.10` | Ordinary web requests |
| `SENTRY_API_TRACES_SAMPLE_RATE` | `0.25` | Ingestion API requests |
| `SENTRY_JOB_TRACES_SAMPLE_RATE` | `0.05` | Root background-job transactions |
| `SENTRY_PROFILES_SAMPLE_RATE` | `0.10` | Relative to sampled traces; about 1% of ordinary requests |
| `SENTRY_ENABLE_LOGS` | `true` | One structured outcome per controller/job/mailer event |
| `SENTRY_DB_QUERY_SOURCE_THRESHOLD_MS` | `100` | Adds source locations only to slower query spans |

Parent sampling decisions are honored so a distributed trace is complete.
Health checks are excluded. The SDK's backpressure monitor dynamically reduces
trace volume if its transport becomes unhealthy. Review Sentry usage after a
week of representative traffic before raising any rate.

Sidekiq errors report on their first failed attempt by default, giving prompt
visibility. Set `SENTRY_SIDEKIQ_REPORT_AFTER_RETRIES=true` only for workloads
where transient retry failures are expected and the resulting detection delay
is acceptable. `SENTRY_SIDEKIQ_REPORT_ONLY_DEAD_JOBS=true` suppresses jobs that
explicitly opt out of Sidekiq's dead set; it does not by itself wait for retries.

### Alerts, ownership, and releases

- Route `app_module` tags (`feed`, `marketplace`, `ingestion_api`, and so on) to
  the owning team. Alert on new, regressed, and escalating production issues;
  do not alert on every event in an already-known issue.
- Start with a notification for newly failing background jobs and sustained
  server-error rate. Add latency alerts only after normal p75/p95 behavior is
  visible; static thresholds chosen before observing traffic are usually noisy.
- Keep the Sentry GitHub integration connected to the exact repository and map
  the production project to its default branch. The SDK detects the full git or
  Heroku build SHA, which lets Sentry associate regressions, suspect commits,
  source context, and resolved-in-release state.
- Use Sentry issue IDs in commits when deliberately resolving an issue, and
  verify the deployed release before marking a regression resolved.

### AI-agent workflow

Sentry's Seer works best when the issue has the context this integration emits:
release SHA, module and actor tags, the connected trace, structured chronology,
queue timing, profiles, and relevant source locations. Connect the GitHub
integration, enable issue scans first, and initially stop automatic fixes at the
proposed-solution stage. Advance to generated branches or pull requests only
after the suggestions are useful on this codebase; keep `bin/verify`, branch
protection, and human review mandatory.

For external coding agents, use Sentry's hosted MCP endpoint at
`https://mcp.sentry.dev/mcp` with its browser OAuth flow. Prefer an
organization/project-scoped MCP URL and read-only investigation permissions.
Do not paste a Sentry user token into prompts, repository files, or agent config
that will be committed. A useful incident handoff contains the Sentry issue ID,
environment, release, trace ID, affected `app_module`, and the user-visible
impact; it does not contain copied request bodies or credentials.

The recommended investigation sequence for a human or agent is:

1. Confirm the issue is production, new/regressed/escalating, and still present
   in the latest release.
2. Inspect the first and latest events, then the connected trace and its slow or
   failed spans.
3. Read adjacent structured logs and, for latency, the sampled profile. For
   connection incidents, query the
   `citysocial.database_connection.duration` metric by `operation` and `status`.
4. Compare suspect commits and module ownership before proposing a patch.
5. Reproduce locally, add a regression test, run `bin/verify`, and have a human
   review the change before deployment.

References: [Sentry Rails](https://docs.sentry.io/platforms/ruby/guides/rails/),
[Seer](https://docs.sentry.io/product/ai-in-sentry/seer/), and
[Sentry MCP](https://github.com/getsentry/sentry-mcp).
