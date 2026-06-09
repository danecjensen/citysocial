---
description: Implement an approved spec inside a module, then verify
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---
Implement this approved spec: $ARGUMENTS

Rules (from CLAUDE.md — re-read it and the target module's CLAUDE.md first):
- Work inside ONE module. If it needs a new module, stop and use /new-app-module.
- Respect the module contract: depend only on platform_core; cross boundaries
  only via PlatformCore::EventBus or a sibling's app/public API; expose your own
  surface in app/public/<module>/.
- Mirror the feed module's structure (components/feed) as the reference.
- Write the migration, model(s), controller(s), view(s), routes, and events
  wiring. Document every new event in the module's lib/<module>/events.rb.
- Write specs covering the happy path + the edge cases from the spec.

When done, run `bin/verify` and fix anything it flags. Do not stop until
`bin/verify` is green. Then summarize the diff and the new/changed events.
