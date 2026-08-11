class AddHeroPhotoToRestaurantsRestaurants < ActiveRecord::Migration[7.2]
  # Which attached photo represents the restaurant. Null means "the oldest
  # attachment", which is the behaviour every existing row already had.
  def change
    add_column :restaurants_restaurants, :hero_photo_id, :bigint
  end
end
