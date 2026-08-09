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
- Prefer direct product docs and specific local forums; generic searches produce slop.
- Notification-loop question is now well covered (R-005/006/007: comment replies, DM
  badge, feedback status change) — Notifications' DeliverActivity only fans out to
  followers, so each needed a new direct-single-recipient delivery path.
- Competitor feedback boards (Canny, UserVoice) and dev-forum meta boards (Discourse
  meta, Apple DTS) cite cleanly; brand-specific "nextdoor"/"craigslist" searches
  produce slop or fetch failures — avoid those, prefer the former.
- Which columns/data does the app already store per module but never surface in the UI
  (sort by, filter by, export/act on)? Cheap, no-migration wins tend to live there.
- Resident discovery needs explicit search consent; public profile URLs alone do not
  justify a citywide directory, so revisit only when a visibility migration is allowed.

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

### R-008 — Coordinate reliable Austin pickup games
- Date: 2026-08-07
- Type: module-product
- Module: new `pickup_sports` engine
- Product thesis and city-specific differentiation: Give Austin residents a
  roster-first place to find casual games that are actually playable this week:
  explicit sport, date, neighborhood or venue, skill and welcome cues, live capacity,
  a fair waitlist, cancellation state, and turnout. This is not a generic event
  calendar, discussion group, league manager, or chat clone.
- Primary persona and job-to-be-done: An Austin adult — especially a newcomer,
  visitor, rusty beginner, or resident crossing town — wants to find a suitable
  casual game and know there is a spot and enough players before leaving.
- Engagement loop: A host posts a game; residents find it by sport, date, and
  neighborhood and join; roster and capacity changes become visible and waitlisted
  residents are promoted deterministically; participants react by joining, leaving,
  or attending; the host closes attendance and posts the next run. Milestone 1 emits
  notification-ready events but does not claim current Notifications delivery.
- Competitor inspiration and what not to copy: Reuse Meetup's attendee caps,
  waitlists, automatic promotion, and attendance concepts, plus Nextdoor's local
  activity coordination. Do not copy Meetup's paid waitlist priority, mandatory
  group prerequisite, payments, or broad planning surface; do not copy Nextdoor's
  generic chat hierarchy or address-verification model.
- Proposed module name and boundary: Generate `pickup_sports` with
  `bin/rails g app_module pickup_sports`. It owns games and per-game rosters,
  depends only on `platform_core`, stores kernel user ids, resolves identity through
  `PlatformCore::Graph`, references no sibling classes, publishes primitive event
  payloads, and exposes only a read API from `app/public/pickup_sports/`.
- Existing-module overlap analysis: `events` is an externally ingested, read-only
  discovery store with no resident host or RSVP actions. `communities` owns durable
  membership, posts, comments, and votes, not per-game commitments, capacity,
  promotion, cancellation, or attendance. `messaging` remains the private
  conversation owner and is not duplicated.
- MVP vertical slice:
  - Models/data: `PickupSports::Game` owns host, title, sport, start/end,
    neighborhood, venue, skill level, capacity, and lifecycle status;
    `PickupSports::RosterEntry` owns game, resident, and joined/waitlisted/
    attended/absent state, with a unique game/resident constraint and indexes for
    upcoming filters.
  - Routes and primary flow: browse/filter by sport, date, and neighborhood text;
    show; authenticated host create/edit/cancel; join/leave; capacity assigns joined
    versus waitlisted; leaving a joined slot promotes the first waitlisted entry
    inside a game lock/transaction ordered by `created_at, id`; the host closes
    attendance after the start.
  - Events/public APIs: publish `pickup_sports.game_created`,
    `pickup_sports.game_changed`, and `pickup_sports.roster_promoted` with only
    primitive game, actor, and recipient ids, internal target path, and change kind.
    Expose `PickupSports::UpcomingGames` as the read-only public API. Never reference
    Notifications; subscriber delivery is a later milestone.
  - UI states: compose shared components/tokens for empty, open, nearly full, full
    and waitlisted, promoted-on-refresh, canceled, completed, owner controls, and
    validation errors.
  - Tests: model, request, event, public-API, and boundary coverage for ownership,
    authentication, transitions, unique/double join, final-slot contention, FIFO
    promotion, cancellation, attendance closeout, filtering, payloads, and absence
    of sibling dependencies.
- Additive/reversible migration needs: Create `pickup_sports_games` and
  `pickup_sports_roster_entries` with reversible migrations, foreign-key/index
  constraints inside the module's schema, and no destructive auth, payment, or
  external-service changes.
- Expansion path:
  - Recurring game series and host templates
  - A Notifications subscriber for roster and game-change events
  - Lightweight team or position balancing
  - Carefully designed reliability signals with correction and appeal paths
- Repo tie-in: `components/events/config/routes.rb` and
  `components/events/app/controllers/events/events_controller.rb` prove Events is
  browse/show/calendar only and read-only; `components/events/app/models/events/event.rb`
  models discovered happenings, not rosters; `components/communities/config/routes.rb`,
  `community.rb`, and `post.rb` cover discussion membership without per-game
  state; current Notifications event/model files do not accept pickup events.
- Sources:
  - https://www.reddit.com/r/Austin/comments/179ccs9/pickup_soccer_games_around_austin/ — Austin player reports stale or incomplete groups and needs recurring drop-in play (fetched 2026-08-07)
  - https://www.reddit.com/r/Austin/comments/11pgs6s/are_there_any_soccer_pickup_games_in_austin_if_so/ — beginner, location, and availability uncertainty in Austin (fetched 2026-08-07)
  - https://www.reddit.com/r/Austin/comments/12cka6x/pickup_basketball/ — cross-sport demand and list-based court access (fetched 2026-08-07)
  - https://www.reddit.com/r/Austin/comments/1nektvj/pickup_soccer_leagues/ — recurring Austin schedules show structured local supply (fetched 2026-08-07)
  - https://help.meetup.com/hc/en-us/articles/360003883411-Enable-a-Waitlist-for-your-Meetup-event — attendee caps, waitlists, and automatic promotion (fetched 2026-08-07)
  - https://help.meetup.com/hc/en-us/articles/9389668230541-Manage-attendees-and-track-attendance-for-your-Meetup-event-on-the-web — roster, waitlist, check-in, and no-show states (fetched 2026-08-07)
  - https://help.meetup.com/hc/en-us/articles/40708711818637-What-notifications-Meetup-can-send — participant change notifications as later inspiration (fetched 2026-08-07)
  - https://blog.nextdoor.com/2024/07/22/new-communities-feature-opens-lines-of-communication-between-neighbors — nearby activity partners and sports-team coordination (fetched 2026-08-07)
- Grader score: 8/10 (−2: milestone 1 combines several independently reviewable
  workflows; the deduction is not for module size, engine generation, or migrations)
- Status: product-fresh

### R-009 — Share a CitySocial event into existing chats
- Date: 2026-08-07
- Type: app-wide-capability
- Module: platform_core
- Ownership: `platform_core` owns a public `PlatformCore::Ui::ShareComponent`
  and its Stimulus behavior; `events` is only the first milestone consumer and
  supplies public title and canonical URL through that sanctioned API.
- Demand signal: Austin residents and organizers describe local-event discovery and
  attendance moving through friends, DMs, and word of mouth; Meetup treats event-page
  sharing plus copy-link as a standard public-event action.
- Sources:
  - https://www.reddit.com/r/Austin/comments/1iwhcni/how_do_you_find_out_about_austin_events/ — residents send local-event discoveries to friends across fragmented channels (fetched 2026-08-07)
  - https://www.reddit.com/r/Austin/comments/1uipqj1/how_to_get_people_to_join_and_attend_your_meetup/ — Austin organizers and attendees rely on friends, word of mouth, and DM'd details (fetched 2026-08-07)
  - https://help.meetup.com/hc/en-us/articles/360002882691-Sharing-an-event-on-social-media — event-page sharing and an always-available copy-link precedent (fetched 2026-08-07)
  - https://developer.mozilla.org/en-US/docs/Web/API/Navigator/share — feature detection, HTTPS, activation, and failure constraints for native sharing (fetched 2026-08-07)
  - https://developer.mozilla.org/en-US/docs/Web/API/Clipboard_API — secure-context and permission constraints for copy behavior (fetched 2026-08-07)
  - https://aublog.nextdoor.com/2020/11/10/introducing-the-new-anyone-audience — off-platform sharing requires explicit public-audience semantics (fetched 2026-08-07)
- Repo tie-in: `components/events/app/views/events/events/show.html.erb` already has
  ticket and calendar actions; `components/events/config/routes.rb` provides a
  stable public event route; `components/events/package.yml` already depends on
  platform_core; shared components live under
  `components/platform_core/app/public/platform_core/ui/`; Stimulus/importmap are
  already wired in `config/importmap.rb` and `app/javascript/controllers/index.js`.
- Acceptance sketch:
  - The public ShareComponent accepts a title and canonical URL, composes the shared
    ButtonComponent and design tokens, always renders Copy link, and reveals a
    separate native Share action only when `navigator.share` is supported.
  - Copy and native share are click-triggered; secure-context, permission, cancel,
    and failure paths leave the permanent copy fallback usable and report accessible
    success or failure status.
  - Event detail adopts it with CitySocial `event_url(@event)`, never the external
    ticket/source `@event.url`; existing ticket and calendar actions stay unchanged.
  - `/design` documents the component. Component/request tests cover options,
    canonical URL, controller/action/status markup, fallback, and unchanged event
    actions; use existing browser/system tooling for behavior if available, with no
    test dependency added.
  - No route, model, migration, record, counter, provider integration, or new
    dependency is added. Community-post adoption waits for explicit audience rules.
- Engagement loop: A resident shares a public CitySocial event; friends see it in
  the chat they already use and receive that chat's notification; they open the
  canonical CitySocial event and react by coordinating or attending.

### R-005 — Notify community post authors when someone comments on their post
- Date: 2026-08-07
- Module: notifications (crosses via event published by communities)
- Demand signal: Forum users across multiple platforms (Apple Developer Forums,
  Discourse, AnandTech) confirm that the absence of reply/comment notifications
  forces manual re-checking and is an explicitly requested gap; Apple's own DTS
  staff acknowledge it as a known, unaddressed limitation.
- Sources:
  - https://developer.apple.com/forums/thread/656206 — DTS engineer confirms no mechanism notifies users of new posts on a watched thread; staff acknowledge the gap (fetched 2026-08-07)
  - https://meta.discourse.org/t/notification-behavior-with-replies/132920 — staff confirm direct replies to a user's own post are the meaningful notification trigger, distinct from full-thread watch (fetched 2026-08-07)
  - https://forums.anandtech.com/threads/at-main-site-comment-notification-system.2197145 — user explicitly requests reply notification instead of manually re-checking (fetched 2026-08-07)
- Repo tie-in: components/communities/lib/communities/events.rb publishes only
  `communities.community_created` and `communities.post_created` today — no
  comment event exists; components/communities/app/models/communities/post.rb:36-39
  has the `announce_creation` pattern to mirror on
  components/communities/app/models/communities/comment.rb (which already has
  `post_id` and `author_id`, no new columns needed); comments have no reply
  threading (`Comment belongs_to :post` only), so "someone comments on your post"
  is the single, complete notification to build — not a nested-reply variant;
  components/notifications/app/models/notifications/notification.rb `SUPPORTED_EVENTS`
  and components/notifications/app/services/notifications/deliver_activity.rb
  `ACTIVITY` hash are both a follower-fan-out pattern (via `PlatformCore::Graph.follower_ids`)
  that is wrong for this feature — a comment notification has exactly one
  recipient (the post author) already present in the event payload, so this
  needs a new direct-recipient delivery path alongside the existing fan-out one,
  not a reuse of it; components/notifications/lib/notifications/events.rb is the
  subscription wiring point. Grader-caught trap: `Notifications` may depend only
  on `platform_core` (components/notifications/package.yml), so it cannot call
  `Communities::Post`/`Community` to build a deep link — this is exactly why the
  existing `communities.post_created` handler degrades to a static `/communities`
  path today. The fix is for `Comment#announce_creation` to include
  `community_slug:` (via `post.community.slug`, computed inside Communities,
  where that's not a boundary crossing) directly in the event payload, so
  Notifications builds `target_path` from primitive data it already received —
  never from a `Communities::` class reference.
- Acceptance sketch:
  - `Communities::Comment` publishes `communities.comment_created` on create with
    `(comment_id:, post_id:, community_slug:, author_id:, post_author_id:)`,
    mirroring `Post`'s existing `after_create_commit` pattern
  - `Notifications` adds `communities.comment_created` to `SUPPORTED_EVENTS` and a
    new direct-recipient delivery path that notifies `post_author_id` only
    (no follower fan-out), building `target_path` from `community_slug`/`post_id`
    alone (no reference to any `Communities::` class)
  - No notification is created when the commenter is the post's own author
  - Covered by a model spec asserting the event payload (including
    `community_slug`), and a service/request spec asserting the post author gets
    exactly one notification per comment, with a working `target_path`, and none
    when commenting on their own post
- Grader score: 8/10 (−2: original acceptance sketch promised a target_path deep
  link to the specific post that couldn't be built under the Packwerk boundary —
  fixed above by carrying `community_slug` in the event payload before recording)
- Status: consumed (F-025)

### R-006 — Show an unread direct-message badge in the global nav
- Date: 2026-08-07
- Module: messaging
- Demand signal: Users of comparable products with in-app DMs (a community
  platform's own feedback board, Meetup, Discourse) repeatedly ask for unread-DM
  visibility beyond a counter buried inside the messaging screen itself — "is
  anyone able to get notifications when you receive a DM? outside the little
  'Chat +1' at the top right" is a representative, explicit ask.
- Sources:
  - https://ideas.gohighlevel.com/communities/p/direct-message-to-community-member — user explicitly asks for DM visibility beyond the small in-page chat counter (fetched 2026-08-07)
  - https://www.meetup.com/blog/messaging-improvements/ — Meetup's own changelog confirms users expect the unread badge to appear immediately and clear reliably once viewed (fetched 2026-08-07)
  - https://meta.discourse.org/t/feature-request-pm-status-read-unread-indication/53908 — long-running (2016-2023) user demand for better unread/PM visibility; staff acknowledge interest (fetched 2026-08-07)
- Repo tie-in: app/views/layouts/application.html.erb already renders a global
  "Notifications" button in the session area using
  `Notifications::Inbox.unread_count_for(current_user.id)` plus a
  `PlatformCore::Ui::BadgeComponent` when the count is positive — the exact
  pattern to mirror; the "Messages" nav link, by contrast, comes from
  `PlatformCore::Modules.nav_modules` via `nav.with_link` and has no unread
  indicator anywhere outside `/messaging`;
  components/messaging/app/public/messaging/inbox.rb already exposes
  `Messaging::Inbox.unread_count(user_id)`, already used in
  components/messaging/app/controllers/messaging/conversations_controller.rb:20 —
  messaging's public API, safe for the host layout to call directly (no module
  boundary violation); no migration needed, the underlying `read_at`/participant
  columns and their indexes already exist.
- Acceptance sketch:
  - The host layout's session area renders a Messages badge (mirroring the
    Notifications button) that shows `Messaging::Inbox.unread_count(current_user.id)`
    when positive and renders nothing when zero
  - The existing "Messages" nav link and all current `/messaging` behavior are
    unchanged
  - The badge only renders for logged-in users, matching the Notifications
    button's existing conditional
  - Covered by a request/system spec asserting the badge appears when the
    current user has an unread message and is absent when they don't
- Grader score: 10/10
- Status: fresh

### R-007 — Notify feedback submission authors when their submission's status changes
- Date: 2026-08-07
- Module: notifications (crosses via an event already published by feedback)
- Demand signal: Users of comparable feedback-board products (Adobe Workfront's
  community forum, Canny) expect to be notified automatically when a submission
  they authored changes status, instead of manually re-checking the board; Canny
  ships this as default behavior explicitly framed as "closing the feedback loop."
- Sources:
  - https://experienceleaguecommunities.adobe.com/adobe-workfront-23/send-a-notification-to-voter-once-the-idea-changes-its-status-134665 — user complains they voted/subscribed to an idea but got no alert when its status changed, asks for automation (fetched 2026-08-07)
  - https://help.canny.io/en/articles/1291127-status-change-emails — Canny's own docs confirm submitters/voters are notified by default when a post's status updates, framed as "closing the feedback loop" (fetched 2026-08-07)
- Repo tie-in: components/feedback/app/models/feedback/submission.rb already has
  `after_update_commit :publish_status_changed, if: :saved_change_to_status?`
  publishing `feedback.submission_status_changed` with
  `(submission_id:, author_id:, status:)` — Feedback needs zero changes, this is
  purely a Notifications-side subscription; components/notifications/lib/notifications/events.rb
  only subscribes to `feed.post_created`/`communities.post_created` today;
  components/notifications/app/services/notifications/deliver_activity.rb's
  follower-fan-out `ACTIVITY` pattern cannot be reused as-is since here the
  recipient IS the author_id, not their followers (same "single direct
  recipient" gap as R-005); components/notifications/app/models/notifications/notification.rb
  has a unique index on `(recipient_id, event_name, source_id)`, so a naive
  `find_or_create_by!` (the existing pattern) would only ever notify once per
  submission — the new delivery path must instead find-or-update the existing
  notification row and reset `read_at` to nil on every status change, so each
  transition resurfaces as unread rather than silently no-oping after the first;
  `actor_id` (NOT NULL, no FK) should be set to `author_id` itself since the
  event payload carries no distinct staff actor.
- Acceptance sketch:
  - `Notifications` adds `feedback.submission_status_changed` to
    `SUPPORTED_EVENTS` and subscribes via `Events.subscribe!`
  - A new delivery path notifies the submission's `author_id` directly (no
    follower fan-out), with `actor_id` set to `author_id`
  - Because of the existing unique index, the delivery path upserts the
    existing notification for that submission (updates `message`, resets
    `read_at` to nil) on every subsequent status change rather than only firing
    once ever
  - No notification is created on submission creation — only on status
    transitions — and the message names the new status (e.g. "Your feedback
    moved to Planned")
  - Covered by a service spec asserting two consecutive status changes on the
    same submission each produce a fresh unread notification, and a request
    spec asserting the author sees it in their inbox
- Grader score: 10/10
- Status: consumed (F-024)
