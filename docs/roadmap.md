# Roadmap

## Shipped
- platform_core: identity, social graph, event bus, public Graph API.
- resident profiles: optional display name, neighborhood, bio, and validated avatar;
  public /people/:handle identity pages, PII-safe Graph snapshot, reusable
  AvatarComponent, cross-module author links, and platform_core.profile_updated.
- feed: reference module (posts + timeline + feed.post_created event).
- design system: Tailwind v4 tokens + PlatformCore::Ui ViewComponents + Hotwire;
  living catalog at /design.
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

## Next (suggested)
- [ ] wire the ATX events routine to emit db/events_feed/<date>.json into this
      repo (adapt v2/atx-events/ROUTINE.md) + a post-deploy `events:ingest` step,
      so the loop actually populates the module in production.
- [ ] notifications module — subscribes to feed.post_created /
      communities.post_created, fans out to followers.
- [ ] messaging module — DMs over the social graph (buyer↔seller, member↔member).
- [ ] production ActiveStorage service (S3/GCS) — dev/test use Disk; Heroku's
      filesystem is ephemeral, so photos need a real bucket before launch.
