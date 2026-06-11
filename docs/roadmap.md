# Roadmap

## Shipped
- platform_core: identity, social graph, event bus, public Graph API.
- feed: reference module (posts + timeline + feed.post_created event).
- design system: Tailwind v4 tokens + PlatformCore::Ui ViewComponents + Hotwire;
  living catalog at /design. All existing views restyled.

## Next (suggested)
- [ ] notifications module — subscribes to feed.post_created, fans out to followers.
- [ ] messaging module — DMs over the social graph.
- [ ] marketplace module — listings; emits marketplace.listing_created.
