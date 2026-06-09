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
      { name: "Clark's Oyster Bar", cuisine: "Seafood", area: "Clarksville" }
    ].freeze

    def seed!
      SEED.each do |attrs|
        Restaurants::Restaurant.find_or_create_by!(name: attrs[:name]) do |r|
          r.cuisine = attrs[:cuisine]
          r.area = attrs[:area]
        end
      end
    end
  end
end
