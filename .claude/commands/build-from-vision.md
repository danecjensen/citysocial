---
description: Decompose a big product vision into a phased, module-by-module roadmap
allowed-tools: Read, Grep, Glob, Write
---
Vision: $ARGUMENTS

Read CLAUDE.md. Produce a phased roadmap (not code):
- Break the vision into modules (each a near-full app) and order them by
  dependency — kernel concerns first, then modules that build on shared events.
- For each module: one-line purpose, the events it publishes/consumes, and the
  single MVP engagement loop to ship first.
- Sequence into phases; each phase ends with a shippable, verifiable slice.
Write the result to docs/roadmap.md, then suggest the first /new-app-module call.
