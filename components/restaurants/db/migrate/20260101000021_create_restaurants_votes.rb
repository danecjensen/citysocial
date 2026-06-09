class CreateRestaurantsVotes < ActiveRecord::Migration[7.2]
  def change
    create_table :restaurants_votes do |t|
      t.bigint :voter_id, null: false
      t.bigint :winner_id, null: false
      t.bigint :loser_id, null: false
      t.timestamps
    end
    add_index :restaurants_votes, :voter_id
    add_index :restaurants_votes, :created_at
  end
end
