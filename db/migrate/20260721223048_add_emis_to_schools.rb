class AddEmisToSchools < ActiveRecord::Migration[8.0]
  def change
    add_column :schools, :emis, :string
    add_index :schools, :emis, unique: true
  end
end