# Home Feed 2.0

## Resident outcome

An Austin resident can quickly share a useful update or local news story, see
relevant public activity from across CitySocial without visiting every module,
and turn that activity into a lightweight conversation.

The engagement loop is: a resident creates a feed post or public module item →
followers and other local residents see its feed card → another resident
comments, reacts, votes, saves, shares, or follows the card to its owning module.

## Acceptance criteria

- The signed-in home feed begins with a prominent composer for text, photos,
  links/news, polls, event shares, marketplace shares, and pickup-game shares.
- Article URLs render a publisher, headline, description, and verified lead
  image when the source exposes them. Preview failure never prevents posting.
- Feed posts have permanent detail pages with comments, like/celebrate/helpful
  reactions, polls, saves, progressive-enhancement sharing, and author-only
  edit/delete controls.
- Public creation/activity events from Communities, Marketplace, Events,
  Shared Calendar, Pickup Sports, and Restaurants are projected idempotently
  into the feed through `PlatformCore::EventBus`.
- Messaging, notifications, and product-feedback workflow events remain out of
  the public feed. Feed never reads a sibling model.
- Resident-authored content and external URLs are absent from analytics event
  properties.

## Measurement

- Resident outcome event: `feed.comment_created`, proving that a feed item
  produced a response. `feed.reaction_changed` and `feed.poll_voted` provide
  secondary response signals; `feed.post_created` is the creation denominator.
- Baseline: establish the current seven-day percentage of feed creations that
  receive a response from a different resident within seven days after launch.
- Target: at least 25% of feed creations receive a different-resident comment,
  reaction, or poll vote within seven days.
- Window: evaluate weekly cohorts for six weeks after at least 100 creations
  have accumulated.
- Minimum sample: 100 feed creations from at least 30 distinct residents; do
  not declare success or failure before both thresholds are met.
- Diagnostic properties: `kind`, `source`, and response `state` only. Do not
  add post titles, bodies, comments, article URLs, or preview text.
