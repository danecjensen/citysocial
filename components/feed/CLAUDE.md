# Feed module

Nested memory for the feed module. Read alongside the root CLAUDE.md. This
module is the **reference implementation** for the conventions -- copy its shape.

## What lives here
- `app/models/feed/post.rb` -- emits `feed.post_created` on create (announce, don't call).
- `app/public/feed/timeline.rb` -- the ONLY entry point other modules may use.
- `lib/feed/events.rb` -- the honest map of what feed publishes/subscribes.

## Boundaries
- Depends ONLY on `platform_core`. To read identity/graph, call `PlatformCore::Graph`.
- To talk to another module, publish/subscribe via `PlatformCore::EventBus`.
- Controllers inherit from `PlatformCore::BaseController`; models from `Feed::ApplicationRecord`.
