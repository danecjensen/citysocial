# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_08_05_170519) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "communities_comments", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.integer "score", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_communities_comments_on_post_id"
  end

  create_table "communities_communities", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "category"
    t.bigint "creator_id", null: false
    t.integer "members_count", default: 0, null: false
    t.integer "posts_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_communities_communities_on_name", unique: true
    t.index ["slug"], name: "index_communities_communities_on_slug", unique: true
  end

  create_table "communities_memberships", force: :cascade do |t|
    t.bigint "community_id", null: false
    t.bigint "user_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id", "user_id"], name: "index_communities_memberships_on_community_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_communities_memberships_on_user_id"
  end

  create_table "communities_posts", force: :cascade do |t|
    t.bigint "community_id", null: false
    t.bigint "author_id", null: false
    t.string "title", null: false
    t.text "body"
    t.string "url"
    t.integer "kind", default: 0, null: false
    t.integer "score", default: 0, null: false
    t.integer "comments_count", default: 0, null: false
    t.boolean "pinned", default: false, null: false
    t.boolean "locked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id"], name: "index_communities_posts_on_community_id"
  end

  create_table "communities_votes", force: :cascade do |t|
    t.string "votable_type", null: false
    t.bigint "votable_id", null: false
    t.bigint "user_id", null: false
    t.integer "value", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["votable_type", "votable_id", "user_id"], name: "index_communities_votes_uniqueness", unique: true
  end

  create_table "events_events", force: :cascade do |t|
    t.string "fingerprint", null: false
    t.string "title", null: false
    t.text "description"
    t.string "venue"
    t.string "category", default: "other", null: false
    t.string "url"
    t.string "image_url"
    t.datetime "starts_at", null: false
    t.datetime "ends_at"
    t.string "price"
    t.float "score", default: 0.0, null: false
    t.float "confidence", default: 1.0, null: false
    t.string "source"
    t.datetime "last_seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_events_events_on_category"
    t.index ["fingerprint"], name: "index_events_events_on_fingerprint", unique: true
    t.index ["starts_at", "score"], name: "index_events_events_on_starts_at_and_score"
    t.index ["starts_at"], name: "index_events_events_on_starts_at"
  end

  create_table "feed_posts", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id", "created_at"], name: "index_feed_posts_on_author_id_and_created_at"
  end

  create_table "feedback_submissions", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.string "kind", default: "idea", null: false
    t.string "status", default: "open", null: false
    t.string "area"
    t.string "page_url"
    t.string "title", null: false
    t.text "description", null: false
    t.integer "supports_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["area"], name: "index_feedback_submissions_on_area"
    t.index ["author_id"], name: "index_feedback_submissions_on_author_id"
    t.index ["kind"], name: "index_feedback_submissions_on_kind"
    t.index ["status", "supports_count"], name: "index_feedback_submissions_on_status_and_supports_count"
    t.index ["status"], name: "index_feedback_submissions_on_status"
  end

  create_table "feedback_supports", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id", "user_id"], name: "index_feedback_supports_on_submission_id_and_user_id", unique: true
    t.index ["submission_id"], name: "index_feedback_supports_on_submission_id"
    t.index ["user_id"], name: "index_feedback_supports_on_user_id"
  end

  create_table "marketplace_listings", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.string "title", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "category", null: false
    t.string "condition"
    t.integer "price_cents"
    t.string "location"
    t.integer "status", default: 0, null: false
    t.integer "views_count", default: 0, null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_marketplace_listings_on_author_id"
    t.index ["category"], name: "index_marketplace_listings_on_category"
    t.index ["slug"], name: "index_marketplace_listings_on_slug", unique: true
    t.index ["status"], name: "index_marketplace_listings_on_status"
  end

  create_table "notifications_notifications", force: :cascade do |t|
    t.bigint "recipient_id", null: false
    t.bigint "actor_id", null: false
    t.string "event_name", null: false
    t.bigint "source_id", null: false
    t.string "message", null: false
    t.string "target_path", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_id", "event_name", "source_id"], name: "index_notifications_delivery_uniqueness", unique: true
    t.index ["recipient_id", "read_at", "created_at"], name: "index_notifications_inbox"
  end

  create_table "platform_core_follows", force: :cascade do |t|
    t.bigint "follower_id", null: false
    t.bigint "followed_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["follower_id", "followed_id"], name: "index_platform_core_follows_on_follower_id_and_followed_id", unique: true
  end

  create_table "platform_core_modules", force: :cascade do |t|
    t.string "key", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_platform_core_modules_on_key", unique: true
  end

  create_table "platform_core_users", force: :cascade do |t|
    t.string "handle", null: false
    t.string "email", null: false
    t.string "display_name"
    t.string "neighborhood"
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest", null: false
    t.boolean "admin", default: false, null: false
    t.index ["email"], name: "index_platform_core_users_on_email", unique: true
    t.index ["handle"], name: "index_platform_core_users_on_handle", unique: true
  end

  create_table "restaurants_restaurants", force: :cascade do |t|
    t.string "name", null: false
    t.string "cuisine"
    t.string "area"
    t.integer "elo", default: 1500, null: false
    t.integer "matches_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["elo"], name: "index_restaurants_restaurants_on_elo"
    t.index ["name"], name: "index_restaurants_restaurants_on_name", unique: true
  end

  create_table "restaurants_votes", force: :cascade do |t|
    t.bigint "voter_id", null: false
    t.bigint "winner_id", null: false
    t.bigint "loser_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_restaurants_votes_on_created_at"
    t.index ["voter_id"], name: "index_restaurants_votes_on_voter_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "feedback_supports", "feedback_submissions", column: "submission_id"
end
