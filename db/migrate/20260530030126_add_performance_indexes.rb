class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Only add indexes for tables that exist
    add_index :user_schools, [:user_id, :school_id], unique: true, name: "index_user_schools_on_user_id_and_school_id"
    add_index :items, :school_id, name: "index_items_on_school_id" if table_exists?(:items)
    add_index :items, [:school_id, :created_at], name: "index_items_on_school_id_and_created_at" if table_exists?(:items)
    
    # Comment out or remove the recommendations line since the table doesn't exist
    # add_index :recommendations, [:school_id, :item_id], name: "index_recommendations_on_school_id_and_item_id"
  end
end