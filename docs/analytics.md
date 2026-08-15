# Product analytics and AI-agent operating guide

PostHog is CitySocial's product analytics system. Sentry is the source of truth
for exceptions and performance; do not enable PostHog exception, ActiveJob, or
log capture unless that ownership decision is deliberately changed.

The goal is evidence about whether residents quickly accomplish useful local
tasks and create real connections. Page views and clicks are diagnostic context,
not success by themselves.

## Configure an environment

Create a PostHog project for production and set:

```bash
POSTHOG_PROJECT_TOKEN=phc_...
POSTHOG_HOST=https://us.i.posthog.com
```

Use `https://eu.i.posthog.com` for an EU Cloud project. Production enables
PostHog when the project token is present. Development and staging require an
explicit `POSTHOG_ENABLED=true`; use a separate PostHog project so test traffic
cannot merge with resident identities or production funnels.

The project token is intentionally public and is rendered into the browser.
Personal and project-secret API keys are server-only credentials: never add one
to a view, JavaScript, source control, an agent prompt, or a captured property.

If a Content Security Policy is enabled later, allow `https://*.posthog.com` in
`script-src` and `connect-src`, plus `blob:` and `data:` in `worker-src`, or put
PostHog behind a reviewed first-party reverse proxy. Validate browser delivery
after every CSP change because blocked capture calls otherwise fail silently.

## The tracking contract

Feature modules must not call `PostHog` directly. They publish the same
content-free `PlatformCore::EventBus` domain events their engagement loops use.
`PlatformCore::Analytics` turns each publication into one server-side PostHog
event:

- `feed.post_created` becomes `feed post created`.
- The first available action-owner key (`user_id`, `actor_id`, `supporter_id`,
  `resident_id`, `author_id`, `creator_id`, `sender_id`, `voter_id`,
  `recipient_id`, or `host_id`) becomes the stable distinct id
  `user_<database id>`; action owners take precedence over recipients.
- The actor field is removed from event properties. Passwords, tokens, email,
  search/query values, URLs, messages, descriptions, bios, bodies, and content
  fields are dropped by the shared adapter.
- Actorless events are personless, so imports and system routines do not create
  fake PostHog people.
- `domain_event`, `domain_module`, `event_schema_version`, and
  `analytics_source` make provenance queryable.

Authentication is tracked explicitly as `user signed up`, `user logged in`, and
`user logged out`, with only the authentication method. Browser and server SDKs
use the same immutable `user_<id>` distinct id. Email and handle are never
identity keys or person properties.

Autocapture is useful for exploring an unfamiliar flow, but canonical product
metrics should use server domain events. Server events survive JavaScript and ad
blockers, express successful state changes, and are easier to keep stable.

## Privacy defaults

CitySocial displays resident messages, profiles, listings, event details, and
uploaded media, so the browser integration starts from maximum masking:

- all input and visible text is masked in session replay;
- images, video, and elements marked `data-ph-sensitive` are blocked;
- autocapture sends neither element text nor element attributes;
- query strings, fragments, network bodies, and network headers are removed;
- server-side IP properties are removed;
- Do Not Track is respected on a best-effort basis;
- anonymous browser events use person profiles only after identification.

Do not weaken these defaults for a new feature. If a replay needs more context,
add a deliberate, reviewed custom event with categorical or numeric properties.
Never capture free-form resident content to make a replay easier to read.

The app provides technical minimization, not a substitute for a consent and
retention policy. Before public launch, set the project retention period, access
controls, and any consent behavior required for the actual residents and
jurisdictions served.

## Workflow for coding agents

Before implementing a feature, an agent should write down:

1. The resident persona and useful outcome from the feature spec.
2. One existing or proposed domain event that proves the outcome occurred.
3. A funnel or retention question, with a baseline, target, time window, and
   minimum sample size. Avoid targets based only on clicks or page views.
4. The categorical/numeric properties needed to explain the outcome. If raw
   text seems necessary, redesign the property.

During implementation:

1. Publish the domain event from the canonical successful write path, once.
2. Keep its payload content-free and add a spec asserting its name and shape.
3. Reuse a stable event name. Add a new property instead of renaming the event;
   pass a higher `event_schema_version` in the domain payload only when semantics
   truly change.
4. Do not make correctness, authorization, or availability depend on analytics.
   A PostHog outage must leave the resident flow untouched.
5. Run `bin/verify` before treating the instrumentation as complete.

After deployment, use PostHog to compare the declared baseline and target, then
inspect masked replays and resident feedback for explanation. Treat correlation
as a lead, not proof. An agent may recommend or implement a bounded change only
after it records the query, date range, cohort filters, sample size, and the
product hypothesis being tested.

If a PostHog MCP/plugin connection is installed for coding agents, give it the
least-privileged, read-only access available. Keep mutations such as deleting
data, changing retention, editing flags, or launching experiments behind human
approval. Analytics is production evidence, not an autonomous deployment loop.

## First useful insights

Start with a small dashboard tied to the North Star rather than importing every
available chart:

- Activation: `user signed up` to a first meaningful creation/join event within
  seven days.
- Local utility: weekly unique residents completing at least one module-owned
  domain event, broken down by `domain_module`.
- Creation-to-response: a creation event followed by a later interaction event
  from another resident. Add missing response events to the owning module only
  when a concrete feature needs the metric.
- Retention: residents who completed a meaningful event in week zero and again
  in a later week. Do not use login as the retained action.

## Feature flags and experiments

When flags are introduced, evaluate a user's needed flags once per request and
reuse that snapshot. Attach the exact accessed flag values to the corresponding
outcome event. Provide a safe fallback when PostHog is unavailable, never use a
flag as authorization, and remove both flag branches after rollout. Experiments
need a written hypothesis, primary metric, guardrail metric, minimum sample, and
stop rule before exposure begins.

## If CitySocial gains AI features

Coding-agent telemetry and product AI telemetry are separate concerns. Do not
emit AI-observability events merely because AI helped write the code.

If the product later calls an LLM or agent, instrument it with PostHog AI
Observability from day one: one trace id for the user-visible task, spans for
agent/tool steps, and generation records for model calls. Capture model/provider,
prompt version, latency, token usage, cost, errors, and an explicit user outcome.
Default to privacy mode or redacted inputs/outputs; never capture credentials or
private resident content by accident. Maintain a reviewed evaluation dataset,
combine deterministic checks with scored evaluations, and regularly inspect a
small sample of real traces rather than trusting aggregate scores alone.

References: [Rails SDK](https://posthog.com/docs/libraries/ruby-on-rails),
[JavaScript configuration](https://posthog.com/docs/libraries/js/config),
[session replay privacy](https://posthog.com/docs/session-replay/privacy), and
[AI Observability](https://posthog.com/docs/ai-observability/installation).
