# Neighbor Help

Neighbor Help gives city residents a bounded, public-safe commitment ledger for one
small unpaid favor. A requester publishes a neighborhood and time window, one helper
claims or releases the favor, and the requester completes or cancels it. Reports and
admin moderation keep emergency, paid, care, ride, hazardous, contact, and exact-address
content outside the product.

The engine is mounted at `/neighbor_help`, depends only on `platform_core`, resolves
identity through `PlatformCore::Graph`, and publishes content-free lifecycle events
through `PlatformCore::EventBus`.
