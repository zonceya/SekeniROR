class AddColumnsToProvinces < ActiveRecord::Migration[8.0]
  def change
    add_column :provinces, :code, :string
    add_column :provinces, :active, :boolean, default: true
    
    # Add index for faster lookups by code
    add_index :provinces, :code, unique: true
  end
end