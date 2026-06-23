# Add migration for firebase_uid
class AddFirebaseUidToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :firebase_uid, :string
    add_index :users, :firebase_uid, unique: true
  end
end