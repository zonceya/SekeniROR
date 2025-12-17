class AddDisplayNameToShops < ActiveRecord::Migration[8.0]
  def change
    add_column :shops, :display_name, :string
  end
end
