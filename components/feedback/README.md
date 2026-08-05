# Feedback

CitySocial's public product-feedback board. Members can submit general ideas,
report issues, or attach feedback to a stable app area and page URL. Other
members can support a submission, and admins can move it through the public
roadmap states.

## Engagement loop

1. A signed-in member submits an idea or issue.
2. Everyone can discover it on the public board and signed-in members can
   support it once.
3. Admins mark it planned, in progress, completed, or closed.
4. Creation, support, and status changes publish events for a future
   notifications module.

## Events

- `feedback.submission_created`
- `feedback.submission_supported`
- `feedback.submission_status_changed`

The module depends only on `platform_core`; it reads identity through
`PlatformCore::Graph` and does not call sibling modules.
