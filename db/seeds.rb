# Idempotent seeds. Each module exposes its own seeding entrypoint through its
# public API; the host just invokes them.
Restaurants::Catalog.seed!
puts "Seeded #{Restaurants::Restaurant.count} restaurants."
