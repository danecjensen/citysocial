# Roadmap

## Shipped
- product analytics: official PostHog Rails/Ruby SDKs, Turbo-aware browser
  identity, privacy-masked autocapture/session replay, content-free EventBus to
  analytics bridge, authentication lifecycle events, environment-safe setup,
  and a durable measurement/AI-agent operating contract.
- platform_core: identity, social graph, event bus, public Graph API.
- developer portal: admin-only direct CRUD for every application ActiveRecord
  model, with namespaced-model-safe URLs, sortable and paginated record tables,
  complete per-model CSV exports, and validation-aware type-specific forms.
- resident profiles: optional display name, neighborhood, bio, and validated avatar;
  public /people/:handle identity pages, PII-safe Graph snapshot, reusable
  AvatarComponent, cross-module author links, and platform_core.profile_updated.
- feed / Home Feed 2.0: prominent multi-format composer for text, photos,
  article links, polls, and typed event/marketplace/game shares; safe rich news
  previews with verified lead-image ingestion; permanent detail pages; comments,
  like/celebrate/helpful reactions, poll voting, saves, sharing, and owner-only
  edit/delete; idempotent EventBus projections from every public content module
  with source media carried by opaque ActiveStorage blob ids.
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
  = searchable/paginated archive. Curated reasons, ticket urgency, and age limits
  survive ingestion and render with each pick; failed remote artwork degrades to an
  accessible category placeholder. Emits events.events_ingested.
- shared calendar: public, resident-created month calendar with owner-managed
  events, category filtering, responsive desktop grid/mobile agenda, validated
  ActiveStorage event images surfaced in featured cards, calendar cells, and
  detail heroes, plus follower notifications via shared_calendar.event_created.
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
- Google sign-in: kernel-owned "Continue with Google" on the login and signup pages
  via OmniAuth (omniauth-google-oauth2 + rails_csrf_protection middleware in the
  platform_core engine). User.from_omniauth creates an account with a generated
  unique handle and a random password, or links the verified Google email to an
  existing account; provider/uid columns with a unique index. Credentials come from
  GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET.
- ingestion API: kernel-owned, hashed and revocable producer tokens; canonical
  `Feed::PublishPost` and singular `Events::Ingest` write paths; authenticated
  `/api/v1/posts` and `/api/v1/events` transports with source attribution,
  producer external IDs, deterministic event fingerprinting, and retry-safe
  created/updated/duplicate responses.

## Next (suggested)
- [ ] deploy the event curation-field migration. `CITYSOCIAL_INGEST_TOKEN` is
      configured in the Claude cloud routine, which posts its final daily picks to
      the production event API and reports created/updated/duplicate/failed counts.
- [ ] production ActiveStorage service (S3/GCS) — dev/test use Disk; Heroku's
      filesystem is ephemeral, so photos need a real bucket before launch.
- [ ] pickup sports milestone 2 — host attendance closeout after game time, with
      attended/absent roster state and explicit correction paths.
- [ ] pickup sports milestone 3 — recurring game templates plus a Notifications
      subscriber for promotions and host changes.
