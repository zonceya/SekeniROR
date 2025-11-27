# app/models/admin_user.rb
class AdminUser < ApplicationRecord
    has_secure_password
  
    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  
    # For password reset functionality
    def generate_password_reset_token
      self.reset_password_token = SecureRandom.urlsafe_base64
      self.reset_password_sent_at = Time.now
      save!
    end
  end