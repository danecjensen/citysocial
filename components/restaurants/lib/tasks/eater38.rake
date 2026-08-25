# One-off maintenance tasks for reconciling the catalog with Eater Austin's
# "Best Restaurants in Austin" map (the "Eater 38"). The heavy lifting lives in
# Restaurants::Catalog so it stays tested; these are thin, printable wrappers.
#
#   bin/rails restaurants:eater38:missing   # audit only -- list what's absent
#   bin/rails restaurants:eater38:sync      # add any missing ones (idempotent)
namespace :restaurants do
  namespace :eater38 do
    desc "List the Eater 38 (Best Restaurants in Austin) entries missing from the database."
    task missing: :environment do
      total = Restaurants::Catalog::EATER_38.size
      missing = Restaurants::Catalog.missing_eater38

      if missing.empty?
        puts "restaurants:eater38 — all #{total} Eater 38 restaurants are already in the database."
      else
        puts "restaurants:eater38 — #{missing.size} of #{total} missing:"
        missing.each { |name| puts "  - #{name}" }
      end
    end

    desc "Idempotently add any missing Eater 38 (Best Restaurants in Austin) restaurants to the database."
    task sync: :environment do
      total = Restaurants::Catalog::EATER_38.size
      created = Restaurants::Catalog.sync_eater38!

      if created.empty?
        puts "restaurants:eater38:sync — nothing to do; all #{total} Eater 38 restaurants already present."
      else
        puts "restaurants:eater38:sync — added #{created.size} restaurant(s):"
        created.each { |r| puts "  + #{r.name} (#{r.cuisine}, #{r.area})" }
      end

      puts "Database now holds #{Restaurants::Restaurant.count} restaurants."
    end
  end
end
