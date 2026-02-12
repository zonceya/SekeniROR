class RebuildItemVariantSystem < ActiveRecord::Migration[8.0]
  def change
    # 1. Remove foreign key constraint from order_items first
    if foreign_key_exists?(:order_items, :item_variants)
      remove_foreign_key :order_items, :item_variants
    end
    
    # 2. Drop problematic tables
    drop_table :item_stock, if_exists: true
    drop_table :item_variants, if_exists: true
    
    # 3. Create proper item_variants table
    create_table :item_variants, id: :uuid do |t|
      t.references :item, null: false, foreign_key: true, type: :uuid
      t.references :size, foreign_key: { to_table: :item_sizes }
      t.references :color, foreign_key: { to_table: :item_colors }
      t.references :condition, foreign_key: { to_table: :item_conditions }
      
      t.string :sku
      t.decimal :price, precision: 10, scale: 2
      t.integer :quantity, default: 0
      t.integer :reserved, default: 0
      t.boolean :is_active, default: true
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end
    
    add_index :item_variants, :sku, unique: true
    add_index :item_variants, [:item_id, :size_id, :color_id, :condition_id], 
              unique: true, name: 'idx_item_variant_unique'
    
    # 4. Remove variant-related columns from items table
    remove_column :items, :quantity, :integer if column_exists?(:items, :quantity)
    remove_column :items, :reserved, :integer if column_exists?(:items, :reserved)
    remove_column :items, :size_id, :bigint if column_exists?(:items, :size_id)
    remove_column :items, :item_condition_id, :bigint if column_exists?(:items, :item_condition_id)
    
    # 5. Add computed columns to items for easy querying
    add_column :items, :total_quantity, :integer, default: 0
    add_column :items, :total_reserved, :integer, default: 0
    add_column :items, :min_price, :decimal, precision: 10, scale: 2
    add_column :items, :max_price, :decimal, precision: 10, scale: 2
    add_column :items, :available_variants_count, :integer, default: 0
    
    # 6. Create stock tracking table (simplified) - OPTIONAL, comment out if not needed
    create_table :stock_movements, id: :uuid do |t|
      t.references :item_variant, null: false, foreign_key: true, type: :uuid
      t.integer :quantity_change, null: false
      t.string :movement_type
      t.string :reference_type
      t.uuid :reference_id
      t.text :notes
      
      t.timestamps
    end
    
    add_index :stock_movements, [:reference_type, :reference_id]
    add_index :stock_movements, :movement_type
    
    # 7. Add trigger to update item aggregates when variants change - FIXED VERSION
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_item_aggregates()
      RETURNS TRIGGER AS $$
      DECLARE
        target_item_id uuid;
      BEGIN
        -- Determine which item_id to update
        IF TG_OP = 'DELETE' THEN
          target_item_id := OLD.item_id;
        ELSE
          target_item_id := NEW.item_id;
        END IF;
        
        -- Update the item aggregates
        UPDATE items 
        SET 
          total_quantity = COALESCE((SELECT SUM(quantity) FROM item_variants WHERE item_id = target_item_id AND is_active = true), 0),
          total_reserved = COALESCE((SELECT SUM(reserved) FROM item_variants WHERE item_id = target_item_id AND is_active = true), 0),
          min_price = (SELECT MIN(price) FROM item_variants WHERE item_id = target_item_id AND is_active = true AND quantity > 0),
          max_price = (SELECT MAX(price) FROM item_variants WHERE item_id = target_item_id AND is_active = true AND quantity > 0),
          available_variants_count = (SELECT COUNT(*) FROM item_variants WHERE item_id = target_item_id AND is_active = true AND quantity > 0),
          updated_at = NOW()
        WHERE id = target_item_id;
        
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
      
      -- Drop trigger if it exists
      DROP TRIGGER IF EXISTS trigger_update_item_aggregates ON item_variants;
      
      -- Create the trigger
      CREATE TRIGGER trigger_update_item_aggregates
      AFTER INSERT OR UPDATE OF quantity, reserved, is_active, price OR DELETE ON item_variants
      FOR EACH ROW EXECUTE FUNCTION update_item_aggregates();
    SQL
    
    # 8. Add category_id to item_types for school categories
    unless column_exists?(:item_types, :category_id)
      add_column :item_types, :category_id, :bigint
      add_foreign_key :item_types, :categories
      add_index :item_types, :category_id
    end
  end
end