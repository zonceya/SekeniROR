# db/migrate/xxxxxxxxx_add_source_fields_to_items.rb
class AddSourceFieldsToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :source_type, :string
    add_column :items, :is_demo, :boolean, default: false
    add_column :items, :is_placeholder, :boolean, default: false
    
    add_index :items, :source_type
    add_index :items, :is_demo
  end
end