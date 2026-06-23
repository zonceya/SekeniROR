class AddViewCountToItems < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :view_count, :integer, default: 0, null: false
    add_index :items, :view_count
  end
end