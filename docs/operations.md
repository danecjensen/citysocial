# Production operations

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
