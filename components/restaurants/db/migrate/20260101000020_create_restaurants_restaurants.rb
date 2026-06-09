class CreateRestaurantsRestaurants < ActiveRecord::Migration[7.2]
  def change
    create_table :restaurants_restaurants do |t|
      t.string :name, null: false
      t.string :cuisine
      t.string :area
      t.integer :elo, null: false, default: 1500
      t.integer :matches_count, null: false, default: 0
      t.timestamps
    end
    add_index :restaurants_restaurants, :name, unique: true
    add_index :restaurants_restaurants, :elo
  end
end
