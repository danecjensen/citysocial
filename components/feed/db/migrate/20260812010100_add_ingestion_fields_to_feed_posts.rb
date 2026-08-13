class AddIngestionFieldsToFeedPosts < ActiveRecord::Migration[7.2]
  def change
    change_column_null :feed_posts, :body, true
    add_column :feed_posts, :title, :string
    add_column :feed_posts, :url, :string
    add_column :feed_posts, :source, :string, null: false, default: "web"
    add_column :feed_posts, :external_id, :string

    add_index :feed_posts, %i[source external_id], unique: true,
                                                    where: "external_id IS NOT NULL",
                                                    name: "index_feed_posts_on_ingestion_identity"
  end
end
