---
description: Run the verify->fix loop until the build is green
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---
Babysit the current working state. Goal: `bin/verify` passes cleanly.

Loop until green or clearly blocked:
1. Run `bin/verify`.
2. If it fails, read the failure (rspec / packwerk / rubocop), find the cause,
   make the smallest correct fix. For packwerk violations, fix the BOUNDARY
   (move logic, route through an event or app/public API) — never just add a
   dependency to package.yml to silence it.
3. Re-run. Repeat.

If you fix the same class of problem twice, append the rule to docs/lessons.md.
When green, stop and report what was wrong and how you fixed it. If genuinely
blocked (needs a human decision), stop and say exactly what you need.
