# Events feed — ingestion contract

This directory is the drop-box the ATX events discovery routine writes to. Each
run commits one JSON file here (named `YYYY-MM-DD.json`); a deploy/cron step then
runs:

```bash
bin/rails events:ingest         # ingests every db/events_feed/*.json
bin/rails events:ingest[db/events_feed/2026-08-06.json]   # or a single file
```

Ingestion is **deterministic and idempotent**: `Events::Ingest` computes a
fingerprint from `title + venue + calendar-day` (Central Time) in Ruby and
upserts by it, so re-running the same feed changes nothing and the same
real-world event never lands twice — no LLM is involved in dedup.

## File shape

Either a bare array, or `{ "events": [ ... ] }`. Each event object:

```json
{
  "title": "La Bohème",                       // required
  "starts_at": "2026-08-08T19:30:00-05:00",   // required, ISO 8601 (offset or Z)
  "ends_at": "2026-08-08T22:00:00-05:00",     // optional
  "venue": "The Long Center",                  // strongly recommended (dedup key)
  "category": "performing_arts",               // one of the categories below; else "other"
  "url": "https://austinopera.org/la-boheme",  // event/ticket page
  "image_url": "https://.../poster.jpg",       // hero image
  "price": "$25+",                             // free-form; blank/omitted => "Free"
  "score": 0.92,                               // taste rank 0..1 (used ONLY to order)
  "confidence": 0.8,                           // optional 0..1
  "source": "austinopera.org"                  // optional provenance
}
```

Unknown keys are ignored. Unparseable `starts_at` or missing `title` => the row
is skipped (counted, not fatal).

## Categories

`performing_arts`, `experimental`, `film`, `music`, `museums`, `tech`,
`outdoors`, `food`, `other`.

The `score` is produced upstream by the routine's taste model. The app never
computes taste itself — it only selects the 10 highest-scoring events in the next
7 days for the home page, and orders search results, in plain SQL.
