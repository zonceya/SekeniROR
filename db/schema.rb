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

ActiveRecord::Schema[8.0].define(version: 2025_02_18_204922) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug"
    t.text "description"
    t.string "icon"
    t.bigint "parent_id"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }

    t.unique_constraint ["slug"], name: "categories_slug_key"
  end

  create_table "item_variants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "item_id"
    t.string "item_type"
    t.string "variant_name"
    t.string "variant_value"
    t.decimal "actual_price"
    t.integer "stock_availability"
    t.jsonb "meta"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "shop_id"
    t.string "name"
    t.text "description"
    t.string "icon"
    t.string "cover_photo"
    t.string "item_type"
    t.integer "status", limit: 2
    t.boolean "deleted", default: false
    t.jsonb "meta"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "my_store_purchases", force: :cascade do |t|
    t.bigint "shop_id"
    t.integer "pending_orders", default: 0
    t.integer "completed_orders", default: 0
    t.integer "canceled_orders", default: 0
    t.integer "item_count", default: 0
    t.decimal "revenue", default: "0.0"
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "order_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "order_id"
    t.uuid "item_id"
    t.string "item_name"
    t.uuid "item_variant_id"
    t.string "item_variant_name"
    t.string "item_variant_value"
    t.decimal "actual_price"
    t.decimal "total_price"
    t.jsonb "meta"
    t.bigint "shop_id"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "shop_id"
    t.decimal "price"
    t.integer "order_status", limit: 2
    t.integer "payment_status", limit: 2
    t.datetime "order_place_time", precision: nil
    t.decimal "rating"
    t.jsonb "meta"
    t.boolean "deleted", default: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.jsonb "shipping_address"
    t.jsonb "billing_address"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "profile_picture"
    t.string "mobile"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "shops", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "user_id"
    t.string "name", null: false
    t.text "description"
    t.string "logo"
    t.string "location"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "user_sessions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "token", limit: 255, null: false
    t.jsonb "meta"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "ended_at", precision: nil
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "email", limit: 255, null: false
    t.string "mobile", limit: 15
    t.string "username", limit: 255
    t.string "auth_mode", limit: 50, null: false
    t.boolean "status", default: true
    t.boolean "deleted", default: false
    t.string "profile_picture", limit: 255
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }

    t.unique_constraint ["username"], name: "users_username_key"
  end

  add_foreign_key "categories", "categories", column: "parent_id", name: "categories_parent_id_fkey", on_delete: :nullify
  add_foreign_key "item_variants", "items", name: "item_variants_item_id_fkey"
  add_foreign_key "order_items", "item_variants", name: "order_items_item_variant_id_fkey"
  add_foreign_key "order_items", "items", name: "order_items_item_id_fkey"
  add_foreign_key "order_items", "orders", name: "order_items_order_id_fkey"
  add_foreign_key "profiles", "users"
  add_foreign_key "shops", "users", name: "shops_user_id_fkey"
  add_foreign_key "user_sessions", "users", name: "user_sessions_user_id_fkey"
end
