# communities

A CitySocial app-module. Mounted at `/communities`. Depends only on
`platform_core`. Communicates with other modules via `PlatformCore::EventBus`.

## Events published

- `communities.community_created` (community_id:, creator_id:)
- `communities.post_created` (post_id:, community_id:, author_id:)

Communities subscribes to nothing.
