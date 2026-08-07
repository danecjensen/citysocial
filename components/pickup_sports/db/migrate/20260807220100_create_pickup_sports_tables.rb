class CreatePickupSportsTables < ActiveRecord::Migration[7.2]
  def change
    create_table :pickup_sports_games do |t|
      t.bigint :host_id, null: false
      t.string :title, null: false
      t.string :sport, null: false
      t.string :skill_level, null: false, default: "all_levels"
      t.string :neighborhood, null: false
      t.string :venue, null: false
      t.text :details
      t.datetime :starts_at, null: false
      t.integer :capacity, null: false
      t.string :status, null: false, default: "open"
      t.timestamps

      t.index %i[status starts_at], name: "index_pickup_sports_games_on_status_and_start"
      t.index %i[sport starts_at], name: "index_pickup_sports_games_on_sport_and_start"
      t.index :host_id
    end

    create_table :pickup_sports_roster_entries do |t|
      t.references :game, null: false, foreign_key: { to_table: :pickup_sports_games }
      t.bigint :resident_id, null: false
      t.string :status, null: false
      t.timestamps

      t.index %i[game_id resident_id], unique: true, name: "index_pickup_sports_roster_uniqueness"
      t.index %i[game_id status created_at], name: "index_pickup_sports_roster_queue"
      t.index :resident_id
    end
  end
end
