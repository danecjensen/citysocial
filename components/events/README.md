# events

A CitySocial app-module. Mounted at `/events`. Depends only on
`platform_core`. Communicates with other modules via `PlatformCore::EventBus`.

All event creation and correction goes through the singular `Events::Ingest`
command. `Events::Ingest.call_many` is only a batch adapter over that command.

## Events published

- `events.event_ingested` (event_id:, source:, external_id:, status:)
  fired by `Events::Ingest` after one event is created or updated.
- `events.events_ingested` (created:, updated:)
  fired by `Events::Ingest.call_many` after a feed run writes rows.

Events subscribes to nothing.
