# platform_core

The shared kernel. Owns identity (`User`), the social graph (`Follow`), the
public graph API (`PlatformCore::Graph`), and the event bus
(`PlatformCore::EventBus`). Every other module depends on this one; this module
depends on nothing.
