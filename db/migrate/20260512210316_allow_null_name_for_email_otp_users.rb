# db/migrate/20260512000002_allow_null_name_for_email_otp_users.rb
class AllowNullNameForEmailOtpUsers < ActiveRecord::Migration[8.0]
  def change
    # Allow NULL values for name column
    change_column_null :users, :name, true
    
    # Add index on auth_mode for faster queries
    add_index :users, :auth_mode
  end
end