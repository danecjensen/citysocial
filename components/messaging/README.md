# Messaging

A CitySocial app-module. Mounted at `/messaging`. Depends only on
`platform_core`. Communicates with other modules via `PlatformCore::EventBus`.

Milestone 1 lets a signed-in resident start a private one-to-one conversation
from another resident's public profile or handle, exchange replies, and see
unread state in an owner-scoped inbox. It publishes the content-free
`messaging.message_created` event so notification delivery can evolve without
coupling this product to another module.
