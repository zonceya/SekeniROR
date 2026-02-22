class AddItemConditionIdToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :item_condition_id, :integer
  end
end
