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

ActiveRecord::Schema[8.0].define(version: 2025_11_01_124027) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "application_logs", id: false, force: :cascade do |t|
    t.string "request_type", limit: 7, null: false
    t.string "endpoint_url", limit: 1024
    t.text "request_header", null: false
    t.text "request_object", null: false
    t.text "response_object", default: "{}", null: false
    t.datetime "date", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.integer "user_id"
    t.integer "status"
    t.check_constraint "request_type::text = ANY (ARRAY['GET'::character varying::text, 'POST'::character varying::text, 'PUT'::character varying::text, 'PATCH'::character varying::text, 'DELETE'::character varying::text])", name: "application_log_request_type_check"
  end

  create_table "brands", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64, null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }

    t.unique_constraint ["name"], name: "brands_name_key"
  end

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

  create_table "configurations", primary_key: "shop_id", id: :bigint, default: nil, force: :cascade do |t|
    t.float "delivery_price", default: 0.0
    t.boolean "is_delivery_available", default: true
    t.boolean "is_order_taken", default: true
  end

  create_table "favorites", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.uuid "item_id"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }

    t.unique_constraint ["user_id", "item_id"], name: "favorites_user_id_item_id_key"
  end

  create_table "flagged_payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "order_id"
    t.decimal "expected_amount", precision: 10, scale: 2
    t.decimal "received_amount", precision: 10, scale: 2
    t.string "reference"
    t.string "bank"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_flagged_payments_on_order_id"
  end

  create_table "genders", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "category", default: "standard", null: false
    t.integer "exact_age"
    t.string "display_name"
    t.string "gender_group"
    t.index ["category", "exact_age"], name: "idx_genders_category_age"
  end

  create_table "holds", force: :cascade do |t|
    t.uuid "item_id", null: false
    t.bigint "user_id", null: false
    t.uuid "order_id"
    t.integer "quantity", null: false
    t.datetime "expires_at", null: false
    t.string "status", default: "awaiting_payment", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_holds_on_expires_at"
    t.index ["item_id"], name: "index_holds_on_item_id"
    t.index ["order_id"], name: "index_holds_on_order_id"
    t.index ["status"], name: "index_holds_on_status"
    t.index ["user_id"], name: "index_holds_on_user_id"
    t.check_constraint "status::text <> 'completed'::text OR order_id IS NOT NULL", name: "check_completed_holds_have_order"
  end

  create_table "item_colors", id: :serial, force: :cascade do |t|
    t.string "name", null: false

    t.unique_constraint ["name"], name: "item_colors_name_key"
  end

  create_table "item_conditions", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"

    t.unique_constraint ["name"], name: "item_conditions_name_key"
  end

  create_table "item_groups", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
  end

  create_table "item_sizes", id: :serial, force: :cascade do |t|
    t.string "name", limit: 32, null: false

    t.unique_constraint ["name"], name: "item_sizes_name_key"
  end

  create_table "item_stock", force: :cascade do |t|
    t.uuid "item_variant_id"
    t.bigint "location_id"
    t.integer "condition_id", limit: 2
    t.integer "quantity"
    t.jsonb "meta"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "item_tags", primary_key: ["item_id", "tag_id"], force: :cascade do |t|
    t.uuid "item_id", null: false
    t.integer "tag_id", null: false
  end

  create_table "item_types", force: :cascade do |t|
    t.bigint "group_id"
    t.string "name", null: false
    t.text "description"
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
    t.integer "color_id", limit: 2
  end

  create_table "items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "shop_id"
    t.string "name"
    t.text "description"
    t.string "icon"
    t.string "cover_photo"
    t.integer "status", limit: 2, default: 1
    t.boolean "deleted", default: false
    t.jsonb "meta"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.bigint "item_type_id"
    t.integer "school_id"
    t.integer "brand_id"
    t.integer "size_id"
    t.string "additional_photo"
    t.string "label"
    t.decimal "price"
    t.integer "quantity", default: 0, null: false
    t.bigint "item_condition_id"
    t.bigint "location_id"
    t.bigint "province_id"
    t.string "label_photo"
    t.integer "gender_id"
    t.integer "reserved", default: 0, null: false
  end

  create_table "locations", force: :cascade do |t|
    t.string "province", null: false
    t.string "state_or_region"
    t.string "country", default: "South Africa"
    t.integer "town_id"
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

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notifiable_type", null: false
    t.bigint "notifiable_id", null: false
    t.string "title"
    t.string "message"
    t.string "notification_type"
    t.string "status"
    t.boolean "read"
    t.datetime "delivered_at"
    t.boolean "firebase_sent"
    t.text "firebase_response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id"], name: "index_notifications_on_user_id"
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
    t.integer "quantity", default: 1, null: false
    t.index ["item_id"], name: "index_order_items_on_item_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "order_transactions", force: :cascade do |t|
    t.uuid "order_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "txn_status", null: false
    t.string "payment_method"
    t.string "bank_ref_num"
    t.string "bank"
    t.datetime "txn_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_ref_num"], name: "index_order_transactions_on_bank_ref_num"
    t.index ["order_id"], name: "index_order_transactions_on_order_id"
    t.index ["txn_status"], name: "index_order_transactions_on_txn_status"
  end

  create_table "orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "shop_id"
    t.decimal "price", default: "0.0"
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
    t.decimal "service_fee", default: "0.0"
    t.decimal "total_amount", default: "0.0"
    t.bigint "buyer_id", null: false
    t.text "cancellation_reason"
    t.datetime "cancelled_at", precision: nil
    t.string "order_number", limit: 20
    t.text "admin_notes"
    t.text "payment_proof"
    t.text "proof_notes"
    t.datetime "paid_at"
    t.string "bank"
    t.index ["buyer_id"], name: "index_orders_on_buyer_id"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.unique_constraint ["order_number"], name: "orders_order_number_key"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "profile_picture"
    t.string "mobile"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "promotions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "item_id"
    t.string "promo_type", limit: 50
    t.datetime "start_date", precision: nil, null: false
    t.datetime "end_date", precision: nil, null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.integer "shop_id", null: false
    t.string "title", limit: 128
    t.text "description"
    t.string "photo_url", limit: 512
    t.boolean "is_active", default: true
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "provinces", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64, null: false

    t.unique_constraint ["name"], name: "provinces_name_key"
  end

  create_table "purchase_history", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "user_id"
    t.uuid "item_id"
    t.datetime "purchased_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "rating", primary_key: "shop_id", id: :bigint, default: nil, force: :cascade do |t|
    t.float "rating", default: 0.0
    t.integer "user_count", default: 0
  end

  create_table "return_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "order_item_id"
    t.text "reason"
    t.string "status", limit: 50, default: "pending"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "schools", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.integer "location_id"
    t.string "school_type", limit: 50
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.integer "province_id"
  end

  create_table "seller_archive", primary_key: ["user_id", "shop_id"], force: :cascade do |t|
    t.integer "user_id", null: false
    t.bigint "shop_id", null: false
    t.datetime "deleted_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "shops", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name", null: false
    t.text "description"
    t.string "logo"
    t.string "location"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "tag_type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "towns", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.integer "province_id"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "transactions", primary_key: "transaction_id", id: { type: :string, limit: 64 }, force: :cascade do |t|
    t.uuid "order_id", null: false
    t.string "bank_transaction_id", limit: 64, null: false
    t.string "currency", limit: 3
    t.string "response_code", limit: 10, null: false
    t.string "response_message", limit: 500, null: false
    t.string "gateway_name", limit: 15
    t.string "bank_name", limit: 500
    t.string "payment_mode", limit: 15
    t.string "checksum_hash", limit: 108
    t.datetime "date", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "user_schools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "user_id"
    t.integer "school_id"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "user_sessions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "token", limit: 255, null: false
    t.jsonb "meta"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "ended_at", precision: nil
    t.index ["token"], name: "index_user_sessions_on_token"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "mobile", limit: 15
    t.string "username", limit: 255
    t.string "auth_mode", limit: 50, default: "default_auth_mode", null: false
    t.boolean "status", default: true
    t.boolean "deleted", default: false
    t.string "profile_picture", limit: 255
    t.string "role", limit: 50, default: "user"
    t.string "password_digest", limit: 255

    t.unique_constraint ["email"], name: "unique_email"
    t.unique_constraint ["username"], name: "users_username_key"
  end

  add_foreign_key "application_logs", "users", name: "application_log_user_id_fkey", on_delete: :nullify
  add_foreign_key "categories", "categories", column: "parent_id", name: "categories_parent_id_fkey", on_delete: :nullify
  add_foreign_key "configurations", "shops", name: "configurations_shop_id_fk"
  add_foreign_key "favorites", "items", name: "favorites_item_id_fkey", on_delete: :cascade
  add_foreign_key "favorites", "users", name: "favorites_user_id_fkey", on_delete: :cascade
  add_foreign_key "flagged_payments", "orders"
  add_foreign_key "holds", "items"
  add_foreign_key "holds", "orders"
  add_foreign_key "holds", "users"
  add_foreign_key "item_stock", "item_conditions", column: "condition_id", name: "item_stock_condition_id_fkey"
  add_foreign_key "item_stock", "item_variants", name: "item_stock_item_variant_id_fkey"
  add_foreign_key "item_stock", "locations", name: "item_stock_location_id_fkey"
  add_foreign_key "item_tags", "items", name: "item_tags_item_id_fkey", on_delete: :cascade
  add_foreign_key "item_tags", "tags", name: "item_tags_tag_id_fkey", on_delete: :cascade
  add_foreign_key "item_types", "item_groups", column: "group_id", name: "item_types_group_id_fkey", on_delete: :nullify
  add_foreign_key "item_variants", "item_colors", column: "color_id", name: "item_variants_color_id_fkey"
  add_foreign_key "item_variants", "items", name: "item_variants_item_id_fkey"
  add_foreign_key "items", "brands", name: "items_brand_id_fkey"
  add_foreign_key "items", "item_conditions", name: "items_item_condition_id_fkey", on_delete: :nullify
  add_foreign_key "items", "item_sizes", column: "size_id", name: "items_size_id_fkey"
  add_foreign_key "items", "item_types", name: "items_item_type_id_fkey", on_delete: :nullify
  add_foreign_key "items", "locations", name: "items_location_id_fkey", on_delete: :nullify
  add_foreign_key "items", "provinces", name: "items_province_id_fkey", on_delete: :nullify
  add_foreign_key "items", "schools", name: "items_school_id_fkey"
  add_foreign_key "locations", "towns", name: "locations_town_id_fkey", on_delete: :nullify
  add_foreign_key "notifications", "users"
  add_foreign_key "order_items", "item_variants", name: "order_items_item_variant_id_fkey"
  add_foreign_key "order_items", "items", name: "order_items_item_id_fkey"
  add_foreign_key "order_items", "orders", name: "order_items_order_id_fkey"
  add_foreign_key "order_transactions", "orders"
  add_foreign_key "orders", "users", column: "buyer_id", name: "fk_buyer"
  add_foreign_key "profiles", "users"
  add_foreign_key "promotions", "items", name: "promotions_item_id_fkey", on_delete: :cascade
  add_foreign_key "promotions", "shops", name: "promotions_shop_id_fkey", on_delete: :cascade
  add_foreign_key "purchase_history", "items", name: "purchase_history_item_id_fkey", on_delete: :cascade
  add_foreign_key "purchase_history", "users", name: "purchase_history_user_id_fkey", on_delete: :cascade
  add_foreign_key "rating", "shops", name: "rating_shop_id_fk"
  add_foreign_key "return_requests", "order_items", name: "return_requests_order_item_id_fkey", on_delete: :cascade
  add_foreign_key "schools", "locations", name: "schools_location_id_fkey"
  add_foreign_key "schools", "provinces", name: "schools_province_id_fkey", on_delete: :nullify
  add_foreign_key "seller_archive", "users", name: "seller_archive_user_id_fk"
  add_foreign_key "shops", "users", name: "shops_user_id_fkey"
  add_foreign_key "towns", "provinces", name: "towns_province_id_fkey", on_delete: :nullify
  add_foreign_key "transactions", "orders", name: "transactions_order_id_fk", on_delete: :cascade
  add_foreign_key "user_schools", "schools", name: "user_schools_school_id_fkey", on_delete: :cascade
  add_foreign_key "user_schools", "users", name: "user_schools_user_id_fkey", on_delete: :cascade
  add_foreign_key "user_sessions", "users", name: "user_sessions_user_id_fkey"
end
