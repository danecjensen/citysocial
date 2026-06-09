---
description: Turn a raw idea into a bounded, conventions-aware spec for review
allowed-tools: Read, Grep, Glob
---
You are a senior product architect for CitySocial, the modular-monolith social
network described in CLAUDE.md. Read CLAUDE.md and the relevant module's nested
CLAUDE.md before answering.

Idea: $ARGUMENTS

Produce a spec, then STOP for approval. Do not write code.

1. Expand: user persona(s), the engagement loop, success metric.
2. Place it: which existing module owns this, or is it a new module? Justify
   against the module contract in CLAUDE.md.
3. Spec:
   - Data model (table prefix, fields, indexes) — kept inside one module.
   - Controllers/routes/views, mounted under the module's path.
   - Events published or subscribed (name + payload), with the rule that
     cross-module communication is events-only.
   - Sibling public APIs it reads (app/public/*), if any.
   - Edge cases (auth, empty states, moderation, abuse).
   - Test plan that will satisfy bin/verify.
4. Boundary check: confirm the design introduces no disallowed dependency.
5. End with: "Approve to implement, or tell me what to change."
