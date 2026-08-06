# Research Log

Written by the feature-research routine (`.claude/routines/feature-research.md`).
Briefs are append-only; feature-loop updates only a brief's `Status` line when it
consumes or rejects one. Do not reorganize this file — it is the research memory.

## Standing Questions

<!--
Read first on every research run. Hard cap: 10 lines. Questions worth re-asking
across runs, with a persona and a place real users talk. Prune answered or
slop-producing questions when adding.
-->

- What do Austin residents say is missing or broken in the neighborhood apps they
  already use (Nextdoor, local subreddits, Facebook groups)?
- What makes people come back daily to community/classifieds/restaurant-ranking apps —
  which notification or "others see it" loops actually retain?
- Generic "reddit"/"nextdoor" search terms produce slop (complaint-board noise, no
  fetchable primary source) — prefer direct competitor product docs (Discourse,
  Craigslist/Kijiji help pages) and App Store reviews, which cited cleanly this run.
- Which columns/data does the app already store per module but never surface in the UI
  (sort by, filter by, export/act on)? Cheap, no-migration wins tend to live there.

## Briefs

<!--
Appended newest-last by the research routine. Schema lives in feature-research.md
Phase 6. Status: fresh | consumed (F-xxx) | rejected (<reason>).
-->

### R-001 — Add a "Top" comment sort option to community posts
- Date: 2026-08-05
- Module: communities
- Demand signal: Discourse forum users repeatedly and explicitly request sorting
  replies by like/vote count instead of only chronologically ("I want the replies
  underneath to be sorted by the number of likes... I will be using AskBot instead
  because discourse does not offer it"), with peer agreement, and staff confirming
  Discourse has no native way to reorder posts within a topic. Facebook's own help
  docs confirm mature community products rank comments by relevance by default, with
  admin-configurable default order.
- Sources:
  - https://meta.discourse.org/t/reordering-a-topic-by-most-liked-or-threaded-replies/295134 — user requests sort-by-likes for replies; peer agreement + churn threat (fetched 2026-08-05)
  - https://meta.discourse.org/t/sort-answers-by-number-of-likes-in-topic/41993 — staff confirm no native reorder-by-likes exists in Discourse (fetched 2026-08-05)
  - https://www.facebook.com/help/195503695742645 — comments ranked by relevance; admin-configurable default order (fetched 2026-08-05)
- Repo tie-in: components/communities/app/models/communities/comment.rb:11 defines only
  `scope :chronological`; components/communities/app/models/communities/votable.rb:13-22
  already keeps a cached `score` column in sync via `cast_vote`;
  components/communities/app/models/communities/post.rb:19 already has an analogous
  `scope :hot` for posts — the pattern to copy; components/communities/app/controllers/communities/posts_controller.rb:8
  hardcodes `.chronological` with no sort param.
- Acceptance sketch:
  - `Communities::Comment` gets a `top` scope ordering by `score desc, created_at desc`
  - Post show page gets a New/Top toggle via a query param, defaulting to New
    (chronological) so current behavior is unchanged by default
  - Switching to Top reorders the comment list by score without altering vote-casting
  - Covered by a model spec for the new scope and a request spec asserting both sort
    orders render the expected comment order
- Grader score: 10/10
- Status: consumed (F-009)

### R-002 — Filter the restaurants leaderboard by cuisine
- Date: 2026-08-05
- Module: restaurants
- Demand signal: Beli (a directly comparable head-to-head restaurant-ranking app)
  users publicly and repeatedly complain it's unfair/incomparable to rank restaurants
  of very different cuisines against each other (Korean BBQ vs. brunch, bagel shop vs.
  fancy dinner), and a UX case study plus press coverage confirm category-scoped
  ranking is expected, already-shipped functionality in the comparable product.
- Sources:
  - https://apps.apple.com/us/app/beli/id1478375386 — App Store review explicitly requesting cuisine-scoped ranking (fetched 2026-08-05)
  - https://medium.com/@aw766/redesigning-beli-what-do-you-find-yummy-1fad45a7cbcc — UX case study: cross-cuisine ranking is "frustrating"/"incomparable"; proposes category-scoping (fetched 2026-08-05)
  - https://www.thecrimson.com/article/2026/2/26/beli-inquiry/ — confirms Beli ships separate categories (bars, bakeries, coffee shops, ice cream) (fetched 2026-08-05)
- Repo tie-in: components/restaurants/app/controllers/restaurants/leaderboard_controller.rb:6
  takes no params at all; `cuisine` is already a plain string column (no migration
  needed) per components/restaurants/db/migrate/20260101000020_create_restaurants_restaurants.rb:5;
  components/restaurants/app/views/restaurants/leaderboard/index.html.erb:27 renders it
  as a read-only Badge today, with no filter control anywhere in the module.
- Acceptance sketch:
  - Leaderboard controller accepts `?cuisine=` and applies a new `by_cuisine` scope
  - A cuisine select (using `PlatformCore::Ui::FormFieldComponent` `type: :select`,
    from F-003) appears above the table, populated from distinct cuisines present
  - With no cuisine selected, the full ranked list renders exactly as today
  - Covered by a request spec asserting the leaderboard narrows to the selected cuisine
- Grader score: 8/10 (−2: a read-only filter doesn't itself tighten a do→see→react
  loop; the cited demand is really about scoping the head-to-head matchup, not the
  results table — a fair, weaker cousin of what users asked for)
- Status: consumed (F-010)

### R-003 — Add an "Add to Calendar" action to the event detail page
- Date: 2026-08-05
- Module: events
- Demand signal: A user of "Our Community" (a directly comparable local-events
  discovery app) named "add to Google Calendar" as the one feature they wished
  existed; the developer's reply confirmed the gap exists today and said they'd
  consider roadmapping it. Single review — thin but specific and citable, and the
  feature is nearly free to ship (no schema, no dependency).
- Sources:
  - https://apps.apple.com/us/app/our-community-local-events/id1575928251 — review + developer reply confirming the missing add-to-calendar feature (fetched 2026-08-05)
- Repo tie-in: components/events/app/views/events/events/show.html.erb has the ticket
  button but nothing calendar-related; components/events/app/models/events/event.rb
  already has `starts_at`/`ends_at`/`venue`/`title`/`description` plus a
  `when_display`/timezone helper to reuse; components/events/db/migrate/20260101000060_create_events_events.rb:15
  confirms `ends_at` already exists (nullable — needs a fallback duration).
- Acceptance sketch:
  - Event show page adds a Google Calendar link built from existing fields via a URL
    template (no external call, no new dependency)
  - Event show page adds a downloadable `.ics` file (plain-text VCALENDAR) via one new
    read-only controller action, with a defined fallback when `ends_at` is nil
  - Existing ticket-link button and all current page behavior are unchanged
  - Covered by a request spec asserting both the calendar link and the `.ics` response
    render with correct event data
- Grader score: 8/10 (−2: a solo utility — nobody else sees it, nothing published to
  the event bus — net-new surface rather than a loop tightened)
- Status: consumed (F-011)

### R-004 — Let marketplace sellers renew a stale listing
- Date: 2026-08-05
- Module: marketplace
- Demand signal: Craigslist sellers on forums are frustrated that the platform's own
  renew mechanism becomes unavailable outside a ~48-72 hour window, forcing a manual
  delete-and-repost just to regain visibility. Kijiji, a direct classifieds competitor,
  ships a standing "bump to top without extending expiration" feature as a distinct,
  valued capability from renewal.
- Sources:
  - https://www.craigslist.org/about/help/posting/modify/renew — free postings renewable to the top every 48-72 hours (fetched 2026-08-05)
  - https://community.kijiji.ca/basics/bump-up-feature — bump resets position without extending expiration (fetched 2026-08-05)
  - https://www.warriorforum.com/main-internet-marketing-discussion-forum/841117-craigslist-why-do-you-have-delete-repost-some-ads.html — seller forced into delete-and-repost when renew becomes unavailable (fetched 2026-08-05)
  - https://www.drumforum.org/threads/is-there-a-way-to-bump-your-craigs-listings.64808/ — seller explicitly asks for a bump-without-delete option (fetched 2026-08-05)
- Repo tie-in: components/marketplace/app/models/marketplace/listing.rb:24
  (`set_expiration`) and :29 (`scope :recent`) are the two existing levers this reuses
  — no new column needed, since `created_at` is never mass-assigned
  (components/marketplace/app/controllers/marketplace/listings_controller.rb:79-81
  never permits it) and can double as the cooldown clock; :48-51 `mark_sold` is the
  exact member-action pattern to copy; config/routes.rb already has the `post
  :mark_sold` member-route precedent. Note: renewing rewrites the "Posted ... ago"
  timestamp shown at listings/show.html.erb:45 — intended (matches Kijiji's own
  behavior) but should be called out explicitly during implementation.
- Acceptance sketch:
  - Owner-only `renew!` resets `created_at` to now (resurfaces in `recent` order) and
    extends `expires_at` to 30 days from now
  - Renew is blocked within 48 hours of the last renewal/creation, and whenever `sold?`
  - A "Renew" button appears in the existing owner-actions block, hidden/disabled when
    not renewable
  - Covered by a request/model spec asserting renew updates timestamps and is blocked
    inside the cooldown window
- Grader score: 10/10
- Status: consumed (F-012)
