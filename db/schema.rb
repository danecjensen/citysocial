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

ActiveRecord::Schema[7.2].define(version: 2026_01_01_000021) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "feed_posts", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id", "created_at"], name: "index_feed_posts_on_author_id_and_created_at"
  end

  create_table "platform_core_follows", force: :cascade do |t|
    t.bigint "follower_id", null: false
    t.bigint "followed_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["follower_id", "followed_id"], name: "index_platform_core_follows_on_follower_id_and_followed_id", unique: true
  end

  create_table "platform_core_users", force: :cascade do |t|
    t.string "handle", null: false
    t.string "email", null: false
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
end
