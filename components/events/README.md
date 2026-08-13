# events

A CitySocial app-module. Mounted at `/events`. Depends only on
`platform_core`. Communicates with other modules via `PlatformCore::EventBus`.

All event creation and correction goes through the singular `Events::Ingest`
command. `Events::Ingest.call_many` is only a batch adapter over that command.
