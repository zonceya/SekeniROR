# db/migrate/20260512000004_update_existing_users_auth_mode.rb
class UpdateExistingUsersAuthMode < ActiveRecord::Migration[8.0]
  def up
    # Update users with 'email' auth_mode to 'email_otp'
    execute <<-SQL
      UPDATE users 
      SET auth_mode = 'email_otp', 
          email_verified = true 
      WHERE auth_mode = 'email' 
      AND email IS NOT NULL
    SQL
  end

  def down
    # Rollback changes if needed
    execute <<-SQL
      UPDATE users 
      SET auth_mode = 'email', 
          email_verified = false 
      WHERE auth_mode = 'email_otp'
    SQL
  end
end