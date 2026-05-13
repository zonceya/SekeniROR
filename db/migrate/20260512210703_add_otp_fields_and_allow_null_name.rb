# db/migrate/20260512000003_add_otp_fields_and_allow_null_name.rb
class AddOtpFieldsAndAllowNullName < ActiveRecord::Migration[8.0]
  def change
    # Add OTP fields if they don't exist
    unless column_exists?(:users, :otp_code)
      add_column :users, :otp_code, :string
    end
    
    unless column_exists?(:users, :otp_sent_at)
      add_column :users, :otp_sent_at, :datetime
    end
    
    unless column_exists?(:users, :otp_token)
      add_column :users, :otp_token, :string
    end
    
    unless column_exists?(:users, :otp_purpose)
      add_column :users, :otp_purpose, :string
    end
    
    unless column_exists?(:users, :email_verified)
      add_column :users, :email_verified, :boolean, default: false
    end
    
    # Allow NULL values for name column
    change_column_null :users, :name, true
    
    # Add indexes
    add_index :users, :otp_token, unique: true, if_not_exists: true
    add_index :users, :auth_mode, if_not_exists: true
  end
end