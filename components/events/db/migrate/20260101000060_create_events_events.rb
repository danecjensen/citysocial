class CreateEventsEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :events_events do |t|
      # Deterministic dedup key, computed in Ruby from normalized
      # title + venue + start date. The unique index is what actually
      # enforces "one row per real-world event" at the database level.
      t.string   :fingerprint, null: false
      t.string   :title, null: false
      t.text     :description
      t.string   :venue
      t.string   :category, null: false, default: "other"
      t.string   :url
      t.string   :image_url
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string   :price
      # Ranking value produced upstream (the routine's taste model). The
      # module only ever *selects/orders* by it — never computes taste itself.
      t.float    :score, null: false, default: 0.0
      t.float    :confidence, null: false, default: 1.0
      t.string   :source
      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :events_events, :fingerprint, unique: true
    add_index :events_events, :starts_at
    add_index :events_events, :category
    add_index :events_events, %i[starts_at score]
  end
end
