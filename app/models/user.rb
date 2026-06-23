# app/models/user.rb
class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_many :user_sessions, dependent: :destroy
  has_one :shop, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_secure_password validations: false
  has_one :digital_wallet, dependent: :destroy
  has_many :buyer_chat_rooms, class_name: 'ChatRoom', foreign_key: 'buyer_id'
  has_many :seller_chat_rooms, class_name: 'ChatRoom', foreign_key: 'seller_id'
  has_one_attached :profile_picture
  OTP_LENGTH = 6
  OTP_EXPIRY = 15.minutes
  # ADD THESE SCHOOL ASSOCIATIONS
  has_many :user_schools, dependent: :destroy
  has_one :current_school_mapping, -> { order(created_at: :desc) }, class_name: 'UserSchool'
  has_one :current_school, through: :current_school_mapping, source: :school
  
  # ONLY ONE after_create callback
  after_create :create_profile_and_shop
  after_create :create_digital_wallet, unless: :digital_wallet
  
  scope :admins, -> { where(role: 'admin') }
  
  # Password validation
  validates :password, 
            presence: { if: :password_required? },
            length: { minimum: 6, allow_blank: true },
            confirmation: { if: :password_required? }

  def chat_rooms
    ChatRoom.where('buyer_id = ? OR seller_id = ?', id, id)
  end
 
  # Update user without requiring password
  def update_without_password(params)
    if params[:password].blank?
      update(params.except(:password, :password_confirmation))
    else
      update(params)
    end
  end
  def firebase_uid?
    firebase_uid.present?
  end
   def deleted?
    deleted == true
  end
  # Soft delete (makes user inactive)
  def soft_delete
  transaction do
    # Update user status
    update!(
      deleted: true,
      status: false
    )
    
    # ✅ CRITICAL: Clear all school mappings on soft delete
    user_schools.destroy_all
    
    Rails.logger.info "🗑️ User #{id} soft deleted - cleared all school mappings"
  end
end

  def reactivate
  transaction do
    # Reactivate user
    update!(
      deleted: false,
      status: true
    )
    
    # ✅ CRITICAL: Clear any existing school mappings when reactivating
    user_schools.destroy_all
    
    Rails.logger.info "🔄 User #{id} reactivated - school mappings cleared"
  end
end

  def profile_image_url
    if profile_picture.attached?
      Rails.application.routes.url_helpers.url_for(profile_picture)
    else
      "https://cdn.skoolswap.co.za/default_profile.png"
    end
  end
  # app/models/user.rb

def setup_new_user(name = nil, auth_method = 'email_otp')
  update_columns(
    name: name || self.email.split('@').first,
    auth_mode: auth_method,
    status: true,
    deleted: false,
    role: 'user',
    email_verified: true
  )
  
  # Create profile and shop only if they don't exist
  create_profile! unless profile
  create_shop!(name: "#{self.name}'s Shop", description: "Shop for #{self.name}") unless shop
  
  true
end
  # ADD THESE HELPER METHODS FOR SCHOOL
  def school_mapped?
  return false if deleted?  # Deleted users have no school
  user_schools.exists?
end
  
  def school_name
  return nil if deleted?
  current_school&.name
end
  
  def school_id
  return nil if deleted?
  current_school&.id
end

  private

  def create_profile_and_shop
    # Create profile WITHOUT profile_picture (it's handled by Active Storage)
    create_profile! unless profile
    
    # Create shop WITHOUT logo (it's handled by Active Storage)
    create_shop!(name: "#{self.name}'s Shop", description: "Shop for #{self.name}") unless shop
  end

  def password_required?
    false
  end

  def create_digital_wallet
    DigitalWallet.create(user: self) unless digital_wallet
  end

  def set_logout_time
    self.ended_at = Time.current
  end
 
  def generate_password_reset_token
    update(
      reset_password_token: SecureRandom.urlsafe_base64,
      reset_password_sent_at: Time.current
    )
    reset_password_token
  end

  def password_reset_expired?
    reset_password_sent_at < 1.hour.ago
  end
end