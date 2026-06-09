class CreatePlatformCoreFollows < ActiveRecord::Migration[7.2]
  def change
    create_table :platform_core_follows do |t|
      t.bigint :follower_id, null: false
      t.bigint :followed_id, null: false
      t.timestamps
    end
    add_index :platform_core_follows, [:follower_id, :followed_id], unique: true
  end
end
