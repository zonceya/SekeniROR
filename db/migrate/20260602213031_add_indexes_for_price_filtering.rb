# db/migrate/20260602213031_add_indexes_for_price_filtering.rb
class AddIndexesForPriceFiltering < ActiveRecord::Migration[8.0]
  def change
    # Basic price index (only if not exists)
    unless index_exists?(:items, :price)
      add_index :items, :price
    end
    
    # School + price index (only if not exists)
    unless index_exists?(:items, [:school_id, :price])
      add_index :items, [:school_id, :price]
    end
    
    # School + status + deleted + price (only if not exists)
    unless index_exists?(:items, [:school_id, :status, :deleted, :price], name: "index_items_on_school_status_deleted_price")
      add_index :items, [:school_id, :status, :deleted, :price], name: "index_items_on_school_status_deleted_price"
    end
    
    # School + created_at - SKIP because it already exists
    # The error shows this index already exists, so we'll skip it
    
    # Composite index for common query pattern (only if not exists)
    unless index_exists?(:items, [:school_id, :status, :deleted, :created_at, :price], name: "index_items_on_school_status_deleted_created_price")
      add_index :items, [:school_id, :status, :deleted, :created_at, :price], 
                name: "index_items_on_school_status_deleted_created_price"
    end
  end
end