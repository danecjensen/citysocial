class CreateMarketplaceListings < ActiveRecord::Migration[7.2]
  def change
    create_table :marketplace_listings do |t|
      t.bigint  :author_id, null: false
      t.string  :title, null: false
      t.string  :slug, null: false
      t.text    :description
      t.string  :category, null: false
      t.string  :condition
      t.integer :price_cents
      t.string  :location
      t.integer :status, null: false, default: 0
      t.integer :views_count, null: false, default: 0
      t.datetime :expires_at

      t.timestamps
    end

    add_index :marketplace_listings, :slug, unique: true
    add_index :marketplace_listings, :author_id
    add_index :marketplace_listings, :category
    add_index :marketplace_listings, :status
  end
end
