class CreateFeed2Engagement < ActiveRecord::Migration[7.2]
  def change
    change_column_null :feed_posts, :author_id, true

    change_table :feed_posts, bulk: true do |t|
      t.string :kind, null: false, default: "text"
      t.string :target_path
      t.string :preview_title
      t.text :preview_description
      t.string :preview_site_name
      t.integer :comments_count, null: false, default: 0
      t.integer :reactions_count, null: false, default: 0
      t.integer :saves_count, null: false, default: 0
    end
    add_index :feed_posts, :kind

    create_table :feed_comments do |t|
      t.references :post, null: false, foreign_key: { to_table: :feed_posts }
      t.bigint :author_id, null: false
      t.text :body, null: false
      t.timestamps
    end
    add_index :feed_comments, %i[post_id created_at]
    add_index :feed_comments, :author_id

    create_table :feed_reactions do |t|
      t.references :post, null: false, foreign_key: { to_table: :feed_posts }
      t.bigint :user_id, null: false
      t.string :kind, null: false
      t.timestamps
    end
    add_index :feed_reactions, %i[post_id user_id], unique: true

    create_table :feed_saves do |t|
      t.references :post, null: false, foreign_key: { to_table: :feed_posts }
      t.bigint :user_id, null: false
      t.timestamps
    end
    add_index :feed_saves, %i[post_id user_id], unique: true

    create_table :feed_poll_options do |t|
      t.references :post, null: false, foreign_key: { to_table: :feed_posts }
      t.string :label, null: false
      t.integer :votes_count, null: false, default: 0
      t.timestamps
    end

    create_table :feed_poll_votes do |t|
      t.references :post, null: false, foreign_key: { to_table: :feed_posts }
      t.references :poll_option, null: false, foreign_key: { to_table: :feed_poll_options }
      t.bigint :user_id, null: false
      t.timestamps
    end
    add_index :feed_poll_votes, %i[post_id user_id], unique: true
  end
end
