# db/migrate/20260512000001_add_otp_fields_to_users.rb
class AddOtpFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :otp_code, :string
    add_column :users, :otp_sent_at, :datetime
    add_column :users, :otp_token, :string
    add_column :users, :otp_purpose, :string
    add_column :users, :email_verified, :boolean, default: false
    
    add_index :users, :otp_token, unique: true
    add_index :users, :email, unique: true
  end
end