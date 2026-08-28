# marketplace

A CitySocial app-module. Mounted at `/marketplace`. Depends only on
`platform_core`. Communicates with other modules via `PlatformCore::EventBus`.

## Events published

- `marketplace.listing_created` (listing_id:, author_id:)
- `marketplace.listing_sold` (listing_id:, author_id:)

Marketplace subscribes to nothing.
