# Roadmap

## Shipped
- platform_core: identity, social graph, event bus, public Graph API.
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

## Next (suggested)
- [ ] notifications module — subscribes to feed.post_created /
      communities.post_created, fans out to followers.
- [ ] messaging module — DMs over the social graph (buyer↔seller, member↔member).
- [ ] production ActiveStorage service (S3/GCS) — dev/test use Disk; Heroku's
      filesystem is ephemeral, so photos need a real bucket before launch.
