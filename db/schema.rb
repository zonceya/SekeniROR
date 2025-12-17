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

ActiveRecord::Schema[8.0].define(version: 2025_12_13_202400) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "bank_accounts", force: :cascade do |t|
    t.bigint "digital_wallet_id", null: false
    t.string "account_holder_name", null: false
    t.string "bank_name", null: false
    t.string "account_number", null: false
    t.string "branch_code", null: false
    t.string "account_type", default: "savings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_name", "account_number", "branch_code"], name: "index_bank_accounts_unique", unique: true
    t.index ["digital_wallet_id"], name: "index_bank_accounts_on_digital_wallet_id"
  end

  create_table "banners", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "image_url", null: false
    t.string "thumbnail_url"
    t.string "redirect_url"
    t.string "banner_type", default: "home"
    t.uuid "target_id"
    t.string "target_type"
    t.integer "position", default: 0
    t.boolean "active", default: true
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["active"], name: "idx_banners_active", where: "(active = true)"
    t.index ["banner_type"], name: "idx_banners_type"
    t.index ["position"], name: "idx_banners_position"
    t.index ["start_date", "end_date"], name: "idx_banners_dates"
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
    t.string "image_url"

    t.unique_constraint ["slug"], name: "categories_slug_key"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "chat_room_id", null: false
    t.bigint "sender_id", null: false
    t.text "content", null: false
    t.string "message_type", default: "text"
    t.boolean "read", default: false
    t.string "attachment_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_room_id", "created_at"], name: "index_chat_messages_on_chat_room_id_and_created_at"
    t.index ["chat_room_id"], name: "index_chat_messages_on_chat_room_id"
    t.index ["sender_id"], name: "index_chat_messages_on_sender_id"
  end

  create_table "chat_rooms", force: :cascade do |t|
    t.string "room_id", null: false
    t.uuid "order_id", null: false
    t.bigint "buyer_id", null: false
    t.bigint "seller_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_chat_rooms_on_buyer_id"
    t.index ["order_id"], name: "index_chat_rooms_on_order_id"
    t.index ["room_id"], name: "index_chat_rooms_on_room_id", unique: true
    t.index ["seller_id"], name: "index_chat_rooms_on_seller_id"
  end

  create_table "configurations", primary_key: "shop_id", id: :bigint, default: nil, force: :cascade do |t|
    t.float "delivery_price", default: 0.0
    t.boolean "is_delivery_available", default: true
    t.boolean "is_order_taken", default: true
  end

  create_table "digital_wallets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "wallet_number", null: false
    t.decimal "current_balance", precision: 10, scale: 2, default: "0.0"
    t.decimal "pending_balance", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_digital_wallets_on_user_id", unique: true
    t.index ["wallet_number"], name: "index_digital_wallets_on_wallet_number", unique: true
  end

  create_table "disputes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "order_id", null: false
    t.bigint "raised_by_id", null: false
    t.string "dispute_reference", null: false
    t.string "status", null: false
    t.string "reason", null: false
    t.text "description"
    t.json "evidence_photos"
    t.text "admin_notes"
    t.datetime "resolved_at"
    t.bigint "resolved_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dispute_reference"], name: "index_disputes_on_dispute_reference", unique: true
    t.index ["order_id"], name: "index_disputes_on_order_id"
    t.index ["raised_by_id"], name: "index_disputes_on_raised_by_id"
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
    t.index ["id"], name: "idx_items_category"
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

  create_table "pin_verifications", force: :cascade do |t|
    t.uuid "order_id", null: false
    t.bigint "buyer_id", null: false
    t.bigint "seller_id", null: false
    t.string "pin_code", null: false
    t.string "status", default: "pending", null: false
    t.datetime "verified_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_pin_verifications_on_buyer_id"
    t.index ["order_id", "status"], name: "index_pin_verifications_on_order_id_and_status"
    t.index ["order_id"], name: "index_pin_verifications_on_order_id"
    t.index ["pin_code"], name: "index_pin_verifications_on_pin_code"
    t.index ["seller_id"], name: "index_pin_verifications_on_seller_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
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

  create_table "ratings", force: :cascade do |t|
    t.uuid "order_id", null: false
    t.bigint "rater_id", null: false
    t.bigint "rated_id", null: false
    t.bigint "shop_id", null: false
    t.integer "rating", null: false
    t.text "review"
    t.string "rating_type", limit: 20, null: false
    t.timestamptz "created_at", default: -> { "now()" }
    t.timestamptz "updated_at", default: -> { "now()" }
    t.index ["order_id", "rater_id", "rating_type"], name: "unique_rating_per_order_and_type", unique: true
    t.check_constraint "rating >= 1 AND rating <= 5", name: "ratings_rating_check"
    t.check_constraint "rating_type::text = ANY (ARRAY['buyer_to_seller'::character varying, 'seller_to_buyer'::character varying]::text[])", name: "ratings_rating_type_check"
  end

  create_table "refunds", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "order_id", null: false
    t.uuid "dispute_id"
    t.uuid "wallet_transaction_id"
    t.bigint "processed_by_id"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "status", null: false
    t.string "reason", null: false
    t.string "refund_type", null: false
    t.text "notes"
    t.datetime "processed_at"
    t.datetime "estimated_completion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dispute_id"], name: "index_refunds_on_dispute_id"
    t.index ["order_id"], name: "index_refunds_on_order_id"
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

  create_table "seller_strikes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.string "reason", null: false
    t.string "severity", null: false
    t.string "status", default: "active"
    t.datetime "expires_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id"], name: "index_seller_strikes_on_seller_id"
  end

  create_table "shop_ratings", primary_key: "shop_id", id: :bigint, default: nil, force: :cascade do |t|
    t.decimal "average_rating", precision: 3, scale: 2, default: "0.0"
    t.integer "total_ratings", default: 0
    t.integer "rating_1", default: 0
    t.integer "rating_2", default: 0
    t.integer "rating_3", default: 0
    t.integer "rating_4", default: 0
    t.integer "rating_5", default: 0
    t.timestamptz "updated_at", default: -> { "now()" }
    t.datetime "created_at"
  end

  create_table "shops", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name", null: false
    t.text "description"
    t.string "logo"
    t.string "location"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.string "display_name"
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

  create_table "transfer_requests", force: :cascade do |t|
    t.bigint "digital_wallet_id", null: false
    t.bigint "bank_account_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "reference", null: false
    t.string "status", default: "pending", null: false
    t.text "admin_notes"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_account_id"], name: "index_transfer_requests_on_bank_account_id"
    t.index ["digital_wallet_id"], name: "index_transfer_requests_on_digital_wallet_id"
    t.index ["reference"], name: "index_transfer_requests_on_reference", unique: true
    t.index ["status"], name: "index_transfer_requests_on_status"
  end

  create_table "user_ratings", primary_key: "user_id", id: :bigint, default: nil, force: :cascade do |t|
    t.decimal "average_rating", precision: 3, scale: 2, default: "0.0"
    t.integer "total_ratings", default: 0
    t.timestamptz "updated_at", default: -> { "now()" }
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
    t.string "role", limit: 50, default: "user"
    t.string "password_digest", limit: 255
    t.string "firebase_token"

    t.unique_constraint ["email"], name: "unique_email"
    t.unique_constraint ["username"], name: "users_username_key"
  end

  create_table "wallet_transactions", force: :cascade do |t|
    t.bigint "digital_wallet_id", null: false
    t.uuid "order_id"
    t.bigint "transfer_request_id"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.decimal "net_amount", precision: 10, scale: 2, null: false
    t.decimal "service_fee", precision: 10, scale: 2, default: "0.0"
    t.decimal "insurance_fee", precision: 10, scale: 2, default: "0.0"
    t.string "transaction_type", null: false
    t.string "status", default: "pending", null: false
    t.string "transaction_source", null: false
    t.string "description"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_wallet_transactions_on_created_at"
    t.index ["digital_wallet_id"], name: "index_wallet_transactions_on_digital_wallet_id"
    t.index ["order_id"], name: "index_wallet_transactions_on_order_id"
    t.index ["status"], name: "index_wallet_transactions_on_status"
    t.index ["transaction_source"], name: "index_wallet_transactions_on_transaction_source"
    t.index ["transaction_type"], name: "index_wallet_transactions_on_transaction_type"
    t.index ["transfer_request_id"], name: "index_wallet_transactions_on_transfer_request_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "application_logs", "users", name: "application_log_user_id_fkey", on_delete: :nullify
  add_foreign_key "categories", "categories", column: "parent_id", name: "categories_parent_id_fkey", on_delete: :nullify
  add_foreign_key "chat_messages", "chat_rooms"
  add_foreign_key "chat_messages", "users", column: "sender_id"
  add_foreign_key "chat_rooms", "orders"
  add_foreign_key "chat_rooms", "users", column: "buyer_id"
  add_foreign_key "chat_rooms", "users", column: "seller_id"
  add_foreign_key "configurations", "shops", name: "configurations_shop_id_fk"
  add_foreign_key "disputes", "orders"
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
  add_foreign_key "pin_verifications", "orders"
  add_foreign_key "pin_verifications", "users", column: "buyer_id"
  add_foreign_key "pin_verifications", "users", column: "seller_id"
  add_foreign_key "profiles", "users"
  add_foreign_key "promotions", "items", name: "promotions_item_id_fkey", on_delete: :cascade
  add_foreign_key "promotions", "shops", name: "promotions_shop_id_fkey", on_delete: :cascade
  add_foreign_key "purchase_history", "items", name: "purchase_history_item_id_fkey", on_delete: :cascade
  add_foreign_key "purchase_history", "users", name: "purchase_history_user_id_fkey", on_delete: :cascade
  add_foreign_key "ratings", "orders", name: "ratings_order_id_fkey"
  add_foreign_key "ratings", "shops", name: "ratings_shop_id_fkey"
  add_foreign_key "ratings", "users", column: "rated_id", name: "ratings_rated_id_fkey"
  add_foreign_key "ratings", "users", column: "rater_id", name: "ratings_rater_id_fkey"
  add_foreign_key "refunds", "disputes"
  add_foreign_key "refunds", "orders"
  add_foreign_key "return_requests", "order_items", name: "return_requests_order_item_id_fkey", on_delete: :cascade
  add_foreign_key "schools", "locations", name: "schools_location_id_fkey"
  add_foreign_key "schools", "provinces", name: "schools_province_id_fkey", on_delete: :nullify
  add_foreign_key "seller_archive", "users", name: "seller_archive_user_id_fk"
  add_foreign_key "seller_strikes", "users", column: "seller_id"
  add_foreign_key "shop_ratings", "shops", name: "shop_ratings_shop_id_fkey", on_delete: :cascade
  add_foreign_key "shops", "users", name: "shops_user_id_fkey"
  add_foreign_key "towns", "provinces", name: "towns_province_id_fkey", on_delete: :nullify
  add_foreign_key "transactions", "orders", name: "transactions_order_id_fk", on_delete: :cascade
  add_foreign_key "user_ratings", "users", name: "user_ratings_user_id_fkey", on_delete: :cascade
  add_foreign_key "user_schools", "schools", name: "user_schools_school_id_fkey", on_delete: :cascade
  add_foreign_key "user_schools", "users", name: "user_schools_user_id_fkey", on_delete: :cascade
  add_foreign_key "user_sessions", "users", name: "user_sessions_user_id_fkey"
end
