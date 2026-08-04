# Dane's Ideas

My raw idea inbox for CitySocial. I brain-dump here; the autonomous feature loop
(`.claude/routines/feature-loop.md`) reads this file on **every** run, turns ideas into
backlog items, builds them one at a time as draft PRs, and marks each line as it goes.

**How I use it:** under `## Inbox`, add one idea per line as an unchecked box. That's it —
no IDs, no ceremony, stream of consciousness is fine:

```
- [ ] a map view of this week's events
- [ ] let people save an event to a personal list
```

**How the loop marks my lines** (it writes the `` `[…]` `` tag — I never do):

| It looks like | It means |
|---|---|
| `- [ ] idea` | I just added it; the loop hasn't seen it yet |
| `` - [ ] idea `[F-051 queued]` `` | accepted into the backlog, not started yet |
| `` - [ ] idea `[F-051 blocked: needs-human-approval]` `` | it needs me before it can move |
| `` - [x] idea `[F-051 PR #128]` `` | built — a draft PR is open for my review |
| `` - [x] idea `[rejected: <reason>]` `` | the loop won't do it; reason given |
| `` - [x] idea `[dup F-020]` `` | already covered by another item |

A **checked box** means the loop is done with that line (PR opened, rejected, or duplicate).
An **open box with a tag** is still in flight. I just keep adding raw ideas; merging or
closing the PRs keeps the queue draining.

---

## Inbox

<!-- Add ideas below, one per line, as `- [ ] your idea`. Newest on top is fine.
     Leave the tags to the loop — just write the idea. -->
