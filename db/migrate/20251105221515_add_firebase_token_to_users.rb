class AddFirebaseTokenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :firebase_token, :string
  end
end
