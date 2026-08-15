class AddLogoUrlToSchools < ActiveRecord::Migration[8.0]
  def change
    add_column :schools, :logo_url, :string unless column_exists?(:schools, :logo_url)
  end
end