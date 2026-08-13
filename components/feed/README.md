# feed

Hyperlocal feed app-module. Mounted at `/feed`. Reference implementation of the
CitySocial module conventions.

All post creation goes through `Feed::PublishPost`. The authenticated web form,
the ingestion API, runners, jobs, and future transports must call that command
instead of writing `Feed::Post` directly.
