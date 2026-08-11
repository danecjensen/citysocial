# Roadmap

## Shipped
- platform_core: identity, social graph, event bus, public Graph API.
- resident profiles: optional display name, neighborhood, bio, and validated avatar;
  public /people/:handle identity pages, PII-safe Graph snapshot, reusable
  AvatarComponent, cross-module author links, and platform_core.profile_updated.
- feed: reference module (posts + timeline + feed.post_created event).
- design system: Tailwind v4 tokens + PlatformCore::Ui ViewComponents + Hotwire;
  living catalog at /design.
- public sharing: reusable progressive-enhancement ShareComponent with a permanent
  canonical copy-link fallback, optional browser-native sharing, and accessible
  outcome status; Events is the first public surface to adopt it.
- design retheme: emerald/teal + slate palette (ported from reddcraigs), Inter
  type, atxatx favicon/logo, rebuilt NavBar (search + pills) + Footer, and
  class-based dark mode via `.dark` CSS-variable overrides (no per-view `dark:`).
- module registry + admin toggle: PlatformCore::Modules (public API) +
  ModuleFlag; /admin/modules turns modules on/off (hides nav AND blocks routes
  via BaseController#ensure_module_enabled).
- communities: subreddit-style. Community/Membership/Post/Comment/Vote; join,
  post, comment, up/down vote (toggle). Emits communities.community_created,
  communities.post_created.
- marketplace: classified listings with ActiveStorage photos, browse/search/
  category filter, mark sold, my listings. Emits marketplace.listing_created,
  marketplace.listing_sold.
- events: read-only Austin events store fed by the ATX discovery routine.
  Deterministic, code-only dedup (SHA256 of normalized title+venue+calendar-day,
  unique index); Events::Ingest upsert API + `rake events:ingest` over
  db/events_feed/*.json. Home (/events) = the 10 highest-scoring events in the
  next 7 days (taste `score` supplied upstream, selection is pure SQL); /events/all
  = searchable/paginated archive. Emits events.events_ingested.
- feedback: public product ideas and issue reports with optional app-area/page
  context, one support per member, public roadmap statuses, and an admin triage
  queue. Emits feedback.submission_created, feedback.submission_supported, and
  feedback.submission_status_changed for the notification loop.
- notifications: durable follower activity inbox consuming feed.post_created and
  communities.post_created asynchronously; idempotent fan-out over the public
  follow graph, direct feedback-status updates to submission authors, unread badge,
  owner-only read controls, and public unread-count API.
- messaging milestone 1: private one-to-one resident conversations, profile and
  handle entry points, owner-scoped inbox/history, unread/read state, replies,
  and a content-free messaging.message_created event for delivery integrations.
- messaging milestone 2: per-resident archive/restore controls, active and archived
  inbox search by public handle or display name, and automatic reactivation when a
  participant replies.
- messaging milestone 3: Marketplace listings and community posts can start a private
  conversation carrying a validated public context label and internal backlink;
  Messaging owns the context without reading or storing sibling records.
- pickup sports milestone 1: resident-hosted Austin games with sport, skill, time,
  neighborhood, venue, capacity, public rosters, transactional join/leave, fair FIFO
  waitlist promotion, cancellation clarity, notification-ready events, and a public
  upcoming-games read API.
- local bug miner: PropCheck model properties, malformed public-request fuzzing
  with p95/SQL budgets, deterministic pickup-sports state-machine journeys,
  reproducible seeds, deep campaigns, and rack-mini-profiler diagnostics.

## Next (suggested)
- [ ] wire the ATX events routine to emit db/events_feed/<date>.json into this
      repo (adapt v2/atx-events/ROUTINE.md) + a post-deploy `events:ingest` step,
      so the loop actually populates the module in production.
- [ ] production ActiveStorage service (S3/GCS) — dev/test use Disk; Heroku's
      filesystem is ephemeral, so photos need a real bucket before launch.
- [ ] pickup sports milestone 2 — host attendance closeout after game time, with
      attended/absent roster state and explicit correction paths.
- [ ] pickup sports milestone 3 — recurring game templates plus a Notifications
      subscriber for promotions and host changes.
