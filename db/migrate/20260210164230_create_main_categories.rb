# db/migrate/YYYYMMDDHHMMSS_create_main_categories.rb
class CreateMainCategories < ActiveRecord::Migration[8.0]
 def change
    # Check if table already exists (from the other migration)
    unless table_exists?(:main_categories)
      create_table :main_categories do |t|
        t.string :name, null: false
        t.text :description
        t.string :icon_name
        t.integer :display_order, default: 0
        t.boolean :is_active, default: true
        t.timestamps
      end
      
      add_index :main_categories, :name, unique: true
      add_index :main_categories, :display_order
      add_index :main_categories, :is_active
    end
    
    # Also check for school_item_categories and rename if needed
    if table_exists?(:school_item_categories) && !table_exists?(:main_categories)
      # If we have school_item_categories but not main_categories, rename
      rename_table :school_item_categories, :main_categories
    end
  end
end

# db/migrate/YYYYMMDDHHMMSS_create_sub_categories.rb
class CreateSubCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :sub_categories do |t|
      t.references :main_category, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :display_order, default: 0
      t.boolean :is_active, default: true
      t.timestamps
    end
    
    add_index :sub_categories, [:main_category_id, :name], unique: true
    add_index :sub_categories, :display_order
    add_index :sub_categories, :is_active
  end
end

# db/migrate/YYYYMMDDHHMMSS_add_categories_to_items.rb
class AddCategoriesToItems < ActiveRecord::Migration[8.0]
  def change
    # Add columns with foreign keys
    add_reference :items, :main_category, foreign_key: true
    add_reference :items, :sub_category, foreign_key: { to_table: :sub_categories }
    
    # Add to item_types too
    add_reference :item_types, :main_category, foreign_key: true
    add_column :item_types, :is_active, :boolean, default: true
    
    # Add indexes
    add_index :items, :main_category_id
    add_index :items, :sub_category_id
    add_index :item_types, :main_category_id
    add_index :item_types, :is_active
  end
end