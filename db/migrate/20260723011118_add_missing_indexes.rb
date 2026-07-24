# db/migrate/YYYYMMDDHHMMSS_add_missing_indexes.rb
class AddMissingIndexes < ActiveRecord::Migration[8.0]
  def change
    # ================================================================
    # ITEMS - Most common query patterns
    # ================================================================
    
    # School + Category (most common filter)
    add_index :items, [:school_id, :main_category_id], name: 'index_items_on_school_and_category' unless index_exists?(:items, [:school_id, :main_category_id])
    
    # School + Status + Deleted (active items at a school)
    add_index :items, [:school_id, :status, :deleted], name: 'index_items_on_school_status_deleted' unless index_exists?(:items, [:school_id, :status, :deleted])
    
    # Category drill-down
    add_index :items, [:main_category_id, :sub_category_id], name: 'index_items_on_category_subcategory' unless index_exists?(:items, [:main_category_id, :sub_category_id])
    
    # Recent active items
    add_index :items, [:status, :deleted, :created_at], name: 'index_items_on_status_deleted_created' unless index_exists?(:items, [:status, :deleted, :created_at])
    
    # Price filtering with status
    add_index :items, [:price, :status, :deleted], name: 'index_items_on_price_status_deleted' unless index_exists?(:items, [:price, :status, :deleted])
    
    # ================================================================
    # ITEM VARIANTS
    # ================================================================
    
    # Active variants for an item
    add_index :item_variants, [:item_id, :is_active], name: 'index_item_variants_on_item_and_active' unless index_exists?(:item_variants, [:item_id, :is_active])
    
    # Price lookups
    add_index :item_variants, [:price, :item_id], name: 'index_item_variants_on_price_item' unless index_exists?(:item_variants, [:price, :item_id])
    
    # ================================================================
    # ORDER ITEMS
    # ================================================================
    
    # Order-item lookups
    add_index :order_items, [:order_id, :item_id], name: 'index_order_items_on_order_item' unless index_exists?(:order_items, [:order_id, :item_id])
    
    # ================================================================
    # ORDERS
    # ================================================================
    
    # User orders by status
    add_index :orders, [:buyer_id, :order_status], name: 'index_orders_on_buyer_status' unless index_exists?(:orders, [:buyer_id, :order_status])
    
    # Shop orders by status
    add_index :orders, [:shop_id, :order_status], name: 'index_orders_on_shop_status' unless index_exists?(:orders, [:shop_id, :order_status])
    
    # ================================================================
    # USER ITEM VIEWS
    # ================================================================
    
    # User view tracking
    add_index :user_item_views, [:user_id, :item_id], name: 'index_user_item_views_user_item' unless index_exists?(:user_item_views, [:user_id, :item_id])
    
    # ================================================================
    # NOTIFICATIONS
    # ================================================================
    
    # User notifications
    add_index :notifications, [:user_id, :read, :created_at], name: 'index_notifications_user_read_created' unless index_exists?(:notifications, [:user_id, :read, :created_at])
    
    # ================================================================
    # DISPUTES
    # ================================================================
    
    # Disputes by status
    add_index :disputes, [:status, :created_at], name: 'index_disputes_on_status_created' unless index_exists?(:disputes, [:status, :created_at])
    
    # ================================================================
    # REFUNDS
    # ================================================================
    
    # Refunds by status
    add_index :refunds, [:status, :created_at], name: 'index_refunds_on_status_created' unless index_exists?(:refunds, [:status, :created_at])
  end
end