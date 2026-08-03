class CreateCommunitiesTables < ActiveRecord::Migration[7.2]
  def change
    create_table :communities_communities do |t|
      t.string  :name, null: false
      t.string  :slug, null: false
      t.text    :description
      t.string  :category
      t.bigint  :creator_id, null: false
      t.integer :members_count, null: false, default: 0
      t.integer :posts_count, null: false, default: 0

      t.timestamps
    end
    add_index :communities_communities, :slug, unique: true
    add_index :communities_communities, :name, unique: true

    create_table :communities_memberships do |t|
      t.bigint  :community_id, null: false
      t.bigint  :user_id, null: false
      t.integer :role, null: false, default: 0

      t.timestamps
    end
    add_index :communities_memberships, %i[community_id user_id], unique: true
    add_index :communities_memberships, :user_id

    create_table :communities_posts do |t|
      t.bigint  :community_id, null: false
      t.bigint  :author_id, null: false
      t.string  :title, null: false
      t.text    :body
      t.string  :url
      t.integer :kind, null: false, default: 0
      t.integer :score, null: false, default: 0
      t.integer :comments_count, null: false, default: 0
      t.boolean :pinned, null: false, default: false
      t.boolean :locked, null: false, default: false

      t.timestamps
    end
    add_index :communities_posts, :community_id

    create_table :communities_comments do |t|
      t.bigint  :post_id, null: false
      t.bigint  :author_id, null: false
      t.text    :body, null: false
      t.integer :score, null: false, default: 0

      t.timestamps
    end
    add_index :communities_comments, :post_id

    create_table :communities_votes do |t|
      t.string  :votable_type, null: false
      t.bigint  :votable_id, null: false
      t.bigint  :user_id, null: false
      t.integer :value, null: false, default: 0

      t.timestamps
    end
    add_index :communities_votes, %i[votable_type votable_id user_id], unique: true, name: "index_communities_votes_uniqueness"
  end
end
