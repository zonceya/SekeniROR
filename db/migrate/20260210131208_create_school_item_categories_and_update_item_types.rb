# db/migrate/20251218000000_create_school_item_categories_and_update_item_types.rb
class CreateSchoolItemCategoriesAndUpdateItemTypes < ActiveRecord::Migration[7.0]
  def change
    # 1. Add missing columns to existing tables
    add_column :items, :main_category_id, :bigint
    add_column :items, :sub_category_id, :bigint
    add_column :item_types, :main_category_id, :bigint
    add_column :item_types, :is_active, :boolean, default: true
    
    # 2. Create main categories table (school-focused)
    create_table :main_categories do |t|
      t.string :name, null: false
      t.string :description
      t.string :icon_name
      t.integer :display_order, default: 0
      t.boolean :is_active, default: true
      t.timestamps
    end
    
    # 3. Create sub-categories table
    create_table :sub_categories do |t|
      t.references :main_category, null: false, foreign_key: true
      t.string :name, null: false
      t.string :description
      t.integer :display_order, default: 0
      t.boolean :is_active, default: true
      t.timestamps
    end
    
    # 4. Add foreign keys
    add_foreign_key :items, :main_categories, column: :main_category_id
    add_foreign_key :items, :sub_categories, column: :sub_category_id
    add_foreign_key :item_types, :main_categories, column: :main_category_id
    
    # 5. Add indexes
    add_index :items, :main_category_id
    add_index :items, :sub_category_id
    add_index :item_types, :main_category_id
  end
end