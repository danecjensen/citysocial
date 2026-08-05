# restaurants

A CitySocial app-module. Mounted at `/restaurants`. Depends only on
`platform_core`. Communicates with other modules via `PlatformCore::EventBus`.

## Photos (Active Storage)

`Restaurants::Restaurant has_many_attached :photos`. The first attached photo is
the representative image, exposed as `restaurant.hero_photo` and shown in the
matchup cards, the leaderboard, and the admin list. Admins can upload more from
the admin area (`/restaurants/admin/restaurants`).

Curated hero images (one per restaurant, harvested from official sites) ship in
`db/seed_photos/`, with a `name => filename` map in `db/seed_photos/photos.json`.
`Restaurants::Catalog.seed!` attaches them idempotently, so `bin/rails db:seed`
both creates the restaurants and gives each one its photo.

Views reference blobs via `main_app.rails_blob_path(photo, only_path: true)` —
Active Storage's routes live in the host app, not this engine.
