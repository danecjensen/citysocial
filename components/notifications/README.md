# Notifications

CitySocial's resident activity inbox. It depends only on `platform_core`, listens
for activity through `PlatformCore::EventBus`, and fans notifications out over
the shared follow graph without referencing publisher models.
