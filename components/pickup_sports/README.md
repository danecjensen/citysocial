# pickup_sports

A roster-first CitySocial product for reliable resident-hosted pickup games:
upcoming discovery, clear capacity, fair waitlists, and deterministic promotion.
Mounted at `/pickup_sports`; depends only on `platform_core` and publishes
primitive activity through `PlatformCore::EventBus`.

## Events published

- `pickup_sports.game_created` (game_id:, host_id:, target_path:)
- `pickup_sports.game_changed` (game_id:, actor_id:, change_kind:, target_path:)
- `pickup_sports.roster_changed` (game_id:, actor_id:, host_id:, roster_status:, change_kind:, target_path:)
- `pickup_sports.roster_promoted` (game_id:, recipient_id:, host_id:, target_path:)

PickupSports subscribes to nothing.
