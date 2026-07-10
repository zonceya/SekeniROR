# db/migrate/20260707000000_add_external_profile_picture_url_to_users.rb
class AddExternalProfilePictureUrlToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :external_profile_picture_url, :string
  end
end