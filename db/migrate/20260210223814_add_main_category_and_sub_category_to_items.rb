class AddMainCategoryAndSubCategoryToItems < ActiveRecord::Migration[8.0]
  def change
    # Add columns to items table
    add_reference :items, :main_category, foreign_key: true, type: :bigint
    add_reference :items, :sub_category, foreign_key: true, type: :bigint
    
    # Create main_categories table if it doesn't exist
    create_table :main_categories, if_not_exists: true do |t|
      t.string :name, null: false
      t.text :description
      t.string :icon_name
      t.boolean :is_active, default: true
      t.integer :display_order, default: 0
      t.timestamps
    end
    
    # Create sub_categories table if it doesn't exist
    create_table :sub_categories, if_not_exists: true do |t|
      t.string :name, null: false
      t.text :description
      t.references :main_category, foreign_key: true, type: :bigint
      t.boolean :is_active, default: true
      t.integer :display_order, default: 0
      t.timestamps
    end
  end
end

