class CreateFeedPosts < ActiveRecord::Migration[7.2]
  def change
    create_table :feed_posts do |t|
      t.bigint :author_id, null: false
      t.text :body, null: false
      t.timestamps
    end
    add_index :feed_posts, [:author_id, :created_at]
  end
end
