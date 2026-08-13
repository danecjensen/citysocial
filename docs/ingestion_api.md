# Ingestion API

CitySocial exposes bearer-token transports for its canonical post and event
commands:

- `POST /api/v1/posts` → `Feed::PublishPost`
- `POST /api/v1/events` → `Events::Ingest`

The token owns `source` and `user_id`; request bodies cannot impersonate either.
Every API request requires `external_id`, which must be stable within that
producer. Exact retries return HTTP 200 with `status: "duplicate"`. Creates
return 201, changed event payloads return 200 with `status: "updated"`, invalid
payloads return 422, and missing/revoked credentials return 401.

## Issue and revoke a token

Issue one token per producer from a trusted Rails console. The secret is shown
once and only its SHA-256 digest is stored:

```ruby
user = PlatformCore::User.find_by!(handle: "dane")
issued = PlatformCore::ApiTokens.issue!(source: "newsblur-cli", user_id: user.id)
puts issued.token
```

Revoke it by its issued ID:

```ruby
PlatformCore::ApiTokens.revoke!(issued.id)
```

## Publish a post

At least one of `title`, `url`, or `body` is required. Only HTTP(S) URLs are
accepted.

```bash
curl -X POST https://citysocial.example/api/v1/posts \
  -H "Authorization: Bearer $CITYSOCIAL_INGEST_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "external_id": "newsblur-story-abc123",
    "title": "Austin adopts a new mobility plan",
    "url": "https://example.com/austin-mobility",
    "body": "A concise local summary."
  }'
```

## Ingest an event

`title`, `starts_at`, and `external_id` are required. Times should be ISO 8601
with an offset or `Z`.

```bash
curl -X POST https://citysocial.example/api/v1/events \
  -H "Authorization: Bearer $CITYSOCIAL_INGEST_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "external_id": "night-market-2026-08-20",
    "title": "Austin Night Market",
    "venue": "Republic Square",
    "starts_at": "2026-08-20T19:00:00-05:00",
    "category": "food",
    "url": "https://example.com/night-market"
  }'
```

Local scripts may skip HTTP and call the same commands with `bin/rails runner`;
that is another transport into the same write path, not a separate ingestion
implementation.
