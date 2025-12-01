class RemoveProfilePictureColumns < ActiveRecord::Migration[8.0]
   def up
    remove_column :users, :profile_picture if column_exists?(:users, :profile_picture)
    remove_column :profiles, :profile_picture if column_exists?(:profiles, :profile_picture)
  end

  def down
    add_column :users, :profile_picture, :string unless column_exists?(:users, :profile_picture)
    add_column :profiles, :profile_picture, :string unless column_exists?(:profiles, :profile_picture)
  end
end
