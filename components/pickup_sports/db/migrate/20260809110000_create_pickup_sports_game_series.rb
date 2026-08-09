class CreatePickupSportsGameSeries < ActiveRecord::Migration[7.2]
  def change
    create_table :pickup_sports_game_series do |t|
      t.bigint :host_id, null: false
      t.string :title, null: false
      t.string :sport, null: false
      t.string :skill_level, null: false, default: "all_levels"
      t.string :neighborhood, null: false
      t.string :venue, null: false
      t.text :details
      t.datetime :starts_at, null: false
      t.integer :capacity, null: false
      t.integer :occurrences_count, null: false
      t.timestamps

      t.index :host_id
    end

    add_reference :pickup_sports_games,
                  :game_series,
                  foreign_key: { to_table: :pickup_sports_game_series }
    add_column :pickup_sports_games, :series_position, :integer
    add_index :pickup_sports_games,
              %i[game_series_id series_position],
              unique: true,
              name: "index_pickup_sports_games_on_series_position"
  end
end
