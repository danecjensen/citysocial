# Shared calendar

A resident-created community calendar, mounted at `/shared_calendar`. Anyone
can browse the calendar; signed-in residents can add events with an optional
image and manage their own contributions.

The month grid, mobile agenda, and event page all surface attached images. The
module depends only on `platform_core` and publishes
`shared_calendar.event_created` through `PlatformCore::EventBus` so followers
can be notified without crossing module boundaries.
