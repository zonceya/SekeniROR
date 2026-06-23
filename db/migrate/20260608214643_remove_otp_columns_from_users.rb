class RemoveOtpColumnsFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :otp_code, :string if column_exists?(:users, :otp_code)
    remove_column :users, :otp_sent_at, :datetime if column_exists?(:users, :otp_sent_at)
    remove_column :users, :otp_token, :string if column_exists?(:users, :otp_token)
    remove_column :users, :email_verified, :boolean if column_exists?(:users, :email_verified)
  end
end