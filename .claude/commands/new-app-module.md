---
description: Stand up a whole new app-module via the generator, then scope its MVP
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---
Stand up a new module. Input: $ARGUMENTS  (format: "<name> — <purpose>")

1. Run: `bin/rails g app_module <name>`  (this wires Gemfile + routes and writes
   the module's CLAUDE.md — do NOT hand-roll the engine).
2. Run `bundle install`.
3. Read the generated components/<name>/CLAUDE.md and confirm the boundaries.
4. Propose the MVP: the core model(s), one engagement loop, the events it will
   publish, and what (if anything) it reads from siblings' app/public APIs.
   Keep it inside the module contract from the root CLAUDE.md.
5. STOP and present the plan for approval before implementing. On approval,
   hand off to /implement-feature.
