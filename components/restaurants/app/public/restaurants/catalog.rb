module Restaurants
  # PUBLIC api: a curated seed list of Austin restaurants plus an idempotent
  # seeding entrypoint the host (or a sibling) can call. Admins add more through
  # the in-app admin area; this just guarantees a non-empty starting set.
  module Catalog
    module_function

    SEED = [
      { name: "Franklin Barbecue", cuisine: "Barbecue", area: "East Austin" },
      { name: "Uchi", cuisine: "Sushi", area: "South Lamar" },
      { name: "Uchiko", cuisine: "Sushi", area: "Rosedale" },
      { name: "La Barbecue", cuisine: "Barbecue", area: "East Austin" },
      { name: "Veracruz All Natural", cuisine: "Tacos", area: "East Austin" },
      { name: "Suerte", cuisine: "Mexican", area: "East Austin" },
      { name: "Matt's El Rancho", cuisine: "Tex-Mex", area: "South Lamar" },
      { name: "Torchy's Tacos", cuisine: "Tacos", area: "South Congress" },
      { name: "Home Slice Pizza", cuisine: "Pizza", area: "South Congress" },
      { name: "Via 313", cuisine: "Pizza", area: "East Austin" },
      { name: "Salt & Time", cuisine: "Steakhouse", area: "East Austin" },
      { name: "Odd Duck", cuisine: "New American", area: "South Lamar" },
      { name: "Barley Swine", cuisine: "New American", area: "North Burnet" },
      { name: "Loro", cuisine: "Asian Barbecue", area: "South Lamar" },
      { name: "Ramen Tatsu-ya", cuisine: "Ramen", area: "South Lamar" },
      { name: "Kemuri Tatsu-ya", cuisine: "Izakaya", area: "East Austin" },
      { name: "Launderette", cuisine: "New American", area: "East Austin" },
      { name: "Jeffrey's", cuisine: "Fine Dining", area: "Clarksville" },
      { name: "Emmer & Rye", cuisine: "New American", area: "Rainey Street" },
      { name: "Joann's Fine Foods", cuisine: "Diner", area: "South Congress" },
      { name: "Hopdoddy Burger Bar", cuisine: "Burgers", area: "South Congress" },
      { name: "P. Terry's", cuisine: "Burgers", area: "Barton Springs" },
      { name: "Juan in a Million", cuisine: "Tex-Mex", area: "East Austin" },
      { name: "Curra's Grill", cuisine: "Mexican", area: "Travis Heights" },
      { name: "El Naranjo", cuisine: "Mexican", area: "Rainey Street" },
      { name: "Cooper's Old Time Pit Bar-B-Que", cuisine: "Barbecue", area: "Downtown" },
      { name: "Terry Black's Barbecue", cuisine: "Barbecue", area: "Barton Springs" },
      { name: "Micklethwait Craft Meats", cuisine: "Barbecue", area: "East Austin" },
      { name: "Lin Asian Bar", cuisine: "Dumplings", area: "Clarksville" },
      { name: "Sichuan River", cuisine: "Sichuan", area: "North Austin" },
      { name: "Aviary Wine & Kitchen", cuisine: "Wine Bar", area: "South Lamar" },
      { name: "Olamaie", cuisine: "Southern", area: "Downtown" },
      { name: "Comedor", cuisine: "Mexican", area: "Downtown" },
      { name: "Dai Due", cuisine: "Farm-to-Table", area: "East Austin" },
      { name: "Birdie's", cuisine: "New American", area: "East Austin" },
      { name: "Nixta Taqueria", cuisine: "Tacos", area: "East Austin" },
      { name: "Cuantos Tacos", cuisine: "Tacos", area: "East Austin" },
      { name: "Sam's Bar-B-Que", cuisine: "Barbecue", area: "East Austin" },
      { name: "Fonda San Miguel", cuisine: "Mexican", area: "North Loop" },
      { name: "Clark's Oyster Bar", cuisine: "Seafood", area: "Clarksville" },
      { name: "Contigo", cuisine: "New American", area: "Mueller" },
      { name: "Justine's Brasserie", cuisine: "French", area: "East Austin" },
      { name: "Rye", cuisine: "New American", area: "East Austin" },
      { name: "Otoko", cuisine: "Sushi", area: "South Congress" },
      { name: "Kome Sushi Kitchen", cuisine: "Japanese", area: "North Loop" },
      { name: "Wu Chow", cuisine: "Chinese", area: "Downtown" },
      { name: "Din Ho Chinese BBQ", cuisine: "Chinese", area: "North Austin" },
      { name: "Old Thousand", cuisine: "Sichuan", area: "East Austin" },
      { name: "The Peached Tortilla", cuisine: "Asian Fusion", area: "South Lamar" },
      { name: "Gourdough's Big. Fat. Donuts.", cuisine: "Donuts", area: "South Austin" },
      { name: "Guero's Taco Bar", cuisine: "Tex-Mex", area: "South Congress" },
      { name: "El Alma Cafe & Cantina", cuisine: "Mexican", area: "South Congress" },
      { name: "Cisco's Restaurant", cuisine: "Tex-Mex", area: "East Austin" },
      { name: "Tamale House East", cuisine: "Tex-Mex", area: "East Austin" },
      { name: "Rosita's Al Pastor", cuisine: "Tacos", area: "East Austin" },
      { name: "Valentina's Tex Mex BBQ", cuisine: "Barbecue", area: "South Austin" },
      { name: "Interstellar BBQ", cuisine: "Barbecue", area: "East Austin" },
      { name: "LeRoy and Lewis Barbecue", cuisine: "Barbecue", area: "South Austin" },
      { name: "Stiles Switch BBQ", cuisine: "Barbecue", area: "North Austin" },
      { name: "Rudy's Country Store and Bar-B-Q", cuisine: "Barbecue", area: "North Austin" },
      { name: "The Salt Lick", cuisine: "Barbecue", area: "Driftwood" },
      { name: "County Line", cuisine: "Barbecue", area: "Bee Cave Road" },
      { name: "Iron Works Barbecue", cuisine: "Barbecue", area: "Downtown" },
      { name: "Distant Relatives BBQ", cuisine: "Barbecue", area: "East Austin" },
      { name: "Pieous", cuisine: "Wood-Fired Pizza", area: "Cedar Park" },
      { name: "Bufalina", cuisine: "Pizza", area: "East Austin" },
      { name: "Little Deli & Pizzeria", cuisine: "Pizza", area: "Clarksville" },
      { name: "East Side Pies", cuisine: "Pizza", area: "East Austin" },
      { name: "Southside Flying Pizza", cuisine: "Pizza", area: "Zilker" },
      { name: "Pinthouse Pizza", cuisine: "Pizza & Beer", area: "North Austin" },
      { name: "Patrizi's", cuisine: "Italian", area: "South Austin" },
      { name: "L'Oca d'Oro", cuisine: "Italian", area: "East Austin" },
      { name: "Red Ash", cuisine: "Italian", area: "Domain" },
      { name: "Andiamo Ristorante", cuisine: "Italian", area: "North Austin" },
      { name: "Vespaio", cuisine: "Italian", area: "South Congress" },
      { name: "Enoteca Vespaio", cuisine: "Italian", area: "South Congress" },
      { name: "Il Brutto", cuisine: "Italian", area: "East Austin" },
      { name: "Second Bar + Kitchen", cuisine: "New American", area: "Downtown" },
      { name: "Michi Ramen", cuisine: "Ramen", area: "South Lamar" },
      { name: "Daruma Ramen", cuisine: "Ramen", area: "North Austin" },
      { name: "Kirin Court", cuisine: "Chinese", area: "North Austin" },
      { name: "Titaya's Thai Cuisine", cuisine: "Thai", area: "North Austin" },
      { name: "Thai Fresh", cuisine: "Thai", area: "Bouldin Creek" },
      { name: "Sway", cuisine: "Thai", area: "Downtown" },
      { name: "Swadee Thai", cuisine: "Thai", area: "South Austin" },
      { name: "Perla's Seafood and Oyster Bar", cuisine: "Seafood", area: "South Congress" },
      { name: "Quality Seafood Market", cuisine: "Seafood", area: "Hyde Park" },
      { name: "Cherry Creek Catfish", cuisine: "Seafood", area: "South Austin" },
      { name: "Moonshine Patio Bar & Grill", cuisine: "Southern", area: "Downtown" },
      { name: "Hillside Farmacy", cuisine: "New American", area: "East Austin" },
      { name: "June's All Day", cuisine: "Wine Bar", area: "South Congress" },
      { name: "Elizabeth Street Cafe", cuisine: "Vietnamese-French", area: "Bouldin Creek" },
      { name: "Nasha's Ethiopian Kitchen", cuisine: "Ethiopian", area: "East Austin" },
      { name: "Kerbey Lane Cafe", cuisine: "Diner", area: "Central Austin" },
      { name: "Magnolia Cafe", cuisine: "Diner", area: "South Congress" },
      { name: "Shady Grove", cuisine: "American", area: "Barton Springs" },
      { name: "Threadgill's", cuisine: "Southern", area: "North Loop" },
      { name: "Dirty Martin's Place", cuisine: "Burgers", area: "West Campus" },
      { name: "Casino El Camino", cuisine: "Burgers", area: "Downtown" },
      { name: "Top Notch Hamburgers", cuisine: "Burgers", area: "South Austin" },
      { name: "Bartlett's", cuisine: "American", area: "Central Austin" },
      { name: "Fixe", cuisine: "Southern", area: "Downtown" },
      { name: "Eberly", cuisine: "New American", area: "South Austin" },
      { name: "Foreign & Domestic", cuisine: "New American", area: "North Loop" },
      { name: "Chuy's", cuisine: "Tex-Mex", area: "Barton Springs" },
      { name: "Trudy's Texas Star", cuisine: "Tex-Mex", area: "North Austin" },
      { name: "Maudie's Tex-Mex", cuisine: "Tex-Mex", area: "South Lamar" },
      { name: "Manuel's", cuisine: "Tex-Mex", area: "Downtown" },
      { name: "Habanero Mexican Cafe", cuisine: "Mexican", area: "South Austin" },

      # Added to cover every entry on Eater Austin's "Best Restaurants in Austin"
      # map (the "Eater 38"). See EATER_38 below and docs/eater38-austin-sync.md.
      # The other spots on that map were already in the catalog above (a few
      # under a fuller name: Komé => "Kome Sushi Kitchen", Justine's =>
      # "Justine's Brasserie", LeRoy & Lewis => "LeRoy and Lewis Barbecue",
      # Distant Relatives => "Distant Relatives BBQ").
      { name: "Himalaya Kosheli Nepali & Indian", cuisine: "Nepali", area: "North Austin" },
      { name: "Pho Phong Luu", cuisine: "Vietnamese", area: "North Austin" },
      { name: "Usta Kababgy", cuisine: "Middle Eastern", area: "North Austin" },
      { name: "House of Three Gorges", cuisine: "Sichuan", area: "North Austin" },
      { name: "Korea House", cuisine: "Korean", area: "North Shoal Creek" },
      { name: "Bufalina Due", cuisine: "Pizza", area: "Brentwood" },
      { name: "Paprika ATX", cuisine: "Tacos", area: "North Austin" },
      { name: "Allday Pizza", cuisine: "Pizza", area: "Tarrytown" },
      { name: "P Thai's Khao Man Gai & Noodles", cuisine: "Thai", area: "North Loop" },
      { name: "Crown & Anchor Pub", cuisine: "Pub", area: "North Campus" },
      { name: "KG BBQ", cuisine: "Barbecue", area: "East Austin" },
      { name: "Este", cuisine: "Mexican", area: "Cherrywood" },
      { name: "Ensenada ATX", cuisine: "Seafood", area: "East Austin" },
      { name: "Better Half Coffee & Cocktails", cuisine: "Cafe", area: "Clarksville" },
      { name: "Lao'd Bar", cuisine: "Laotian", area: "East Austin" },
      { name: "Fish Shop", cuisine: "Seafood", area: "South Austin" },
      { name: "Canje", cuisine: "Caribbean", area: "East Austin" },
      { name: "Apt 115", cuisine: "Wine Bar", area: "East Austin" },
      { name: "Joe's Bakery & Coffee Shop", cuisine: "Tex-Mex", area: "East Austin" },
      { name: "Dee Dee", cuisine: "Thai", area: "Sunset Valley" },
      { name: "Mercado Sin Nombre", cuisine: "Mexican", area: "East Austin" },
      { name: "Intero", cuisine: "Italian", area: "East Austin" },
      { name: "Bouldin Creek Cafe", cuisine: "Vegetarian", area: "Bouldin Creek" }
    ].freeze

    # The canonical catalog names of the restaurants featured on Eater Austin's
    # "Best Restaurants in Austin" map (austin.eater.com's "Eater 38"), audited
    # 2026-08 against the Summer 2026 edition of that map. Every name here must
    # exist in SEED (a spec guards this); `sync_eater38!` ensures the live
    # database contains all of them. Four map entries resolve to a fuller
    # catalog name already present (see the SEED comment above).
    EATER_38 = [
      "Himalaya Kosheli Nepali & Indian",
      "Pho Phong Luu",
      "Usta Kababgy",
      "House of Three Gorges",
      "Korea House",
      "Bufalina Due",
      "Paprika ATX",
      "Fonda San Miguel",
      "Foreign & Domestic",
      "Kome Sushi Kitchen",
      "Allday Pizza",
      "Uchiko",
      "P Thai's Khao Man Gai & Noodles",
      "Crown & Anchor Pub",
      "KG BBQ",
      "Dai Due",
      "Este",
      "Jeffrey's",
      "Birdie's",
      "Nixta Taqueria",
      "Ensenada ATX",
      "Better Half Coffee & Cocktails",
      "Franklin Barbecue",
      "Lao'd Bar",
      "Fish Shop",
      "Veracruz All Natural",
      "Canje",
      "Apt 115",
      "Joe's Bakery & Coffee Shop",
      "Dee Dee",
      "Mercado Sin Nombre",
      "Odd Duck",
      "La Barbecue",
      "Intero",
      "Justine's Brasserie",
      "Bouldin Creek Cafe",
      "LeRoy and Lewis Barbecue",
      "Distant Relatives BBQ"
    ].freeze

    def seed!
      SEED.each { |attrs| ensure_restaurant!(attrs) }
    end

    # Idempotently ensure every restaurant on the Eater 38 map (see EATER_38)
    # exists in the database, returning only the records this call created.
    # Safe to run against production repeatedly: existing rows are matched by
    # their unique name and left untouched, missing ones are created (with a
    # curated hero photo when one ships for them). This is the targeted one-off
    # reconciliation the `restaurants:eater38:sync` rake task wraps -- it touches
    # only the Eater 38, not the whole SEED catalog.
    def sync_eater38!
      EATER_38.filter_map do |name|
        restaurant, created = ensure_restaurant!(seed_for(name))
        restaurant if created
      end
    end

    # The Eater 38 names not yet present in the database (compared
    # case-insensitively, matching the Restaurant name uniqueness rule).
    def missing_eater38
      present = Restaurants::Restaurant.pluck(:name).map(&:downcase)
      EATER_38.reject { |name| present.include?(name.downcase) }
    end

    # Create the restaurant when it's new (matched by unique name) and attach its
    # curated hero photo. Returns `[restaurant, created]` -- `created` is captured
    # from the create-only block, so it stays accurate even though attaching a
    # photo re-saves the record (which would otherwise reset previously_new_record?).
    def ensure_restaurant!(attrs)
      created = false
      restaurant = Restaurants::Restaurant.find_or_create_by!(name: attrs[:name]) do |r|
        r.cuisine = attrs[:cuisine]
        r.area = attrs[:area]
        created = true
      end
      attach_seed_photo!(restaurant)
      [restaurant, created]
    end

    # The SEED row for a given name, or a name-only fallback. EATER_38 is kept in
    # sync with SEED by a spec, so the fallback is only defensive.
    def seed_for(name)
      seed_index.fetch(name, { name: name })
    end

    def seed_index
      @seed_index ||= SEED.index_by { |attrs| attrs[:name] }
    end

    # Directory of curated hero images shipped with the module, plus a
    # name => filename map (`photos.json`) produced by the image harvester.
    PHOTOS_DIR = Restaurants::Engine.root.join("db", "seed_photos")

    def photo_manifest
      manifest = PHOTOS_DIR.join("photos.json")
      return {} unless manifest.exist?

      @photo_manifest ||= JSON.parse(manifest.read)
    end

    # Idempotently attach the curated hero photo for a restaurant. Skips work
    # when a photo is already attached or no curated image exists for the name.
    def attach_seed_photo!(restaurant)
      return if restaurant.photos.attached?

      filename = photo_manifest[restaurant.name]
      return if filename.blank?

      path = PHOTOS_DIR.join(filename)
      return unless path.exist?

      restaurant.photos.attach(
        io: File.open(path),
        filename: filename,
        content_type: Marcel::MimeType.for(path)
      )
    rescue StandardError => e
      # Attaching a photo enqueues an Active Storage analysis job; an unreachable
      # job backend (e.g. no Redis on Heroku) must NEVER abort seeding or the
      # Eater 38 sync. The restaurant row is already committed and stands; the
      # photo can be backfilled once the backend is healthy. Mirrors the
      # EventBus "a side effect must not fail the domain write" rule.
      report_seed_photo_failure(restaurant, e)
    end

    def report_seed_photo_failure(restaurant, error)
      Sentry.capture_exception(error) if defined?(Sentry) && Sentry.initialized?
      Rails.logger.error(
        "event=restaurant_seed_photo_failed restaurant=#{restaurant.name.inspect} " \
        "error_class=#{error.class.name} error=#{error.message.inspect}"
      )
    end
  end
end
