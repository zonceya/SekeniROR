class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_many :user_sessions, dependent: :destroy
  has_one :shop, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_secure_password validations: false
  has_one :digital_wallet, dependent: :destroy
  has_many :buyer_chat_rooms, class_name: 'ChatRoom', foreign_key: 'buyer_id'
  has_many :seller_chat_rooms, class_name: 'ChatRoom', foreign_key: 'seller_id'
  has_one_attached :profile_picture  # Active Storage - NO profile_picture column needed!
  
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

  # Soft delete (makes user inactive)
  def soft_delete
    update(deleted: true)
  end

  def reactivate
    update(deleted: false)
  end

  def profile_image_url
    if profile_picture.attached?
      Rails.application.routes.url_helpers.url_for(profile_picture)
    else
      "https://cdn.skoolswap.co.za/default_profile.png"
    end
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

  # REMOVE THESE CONFLICTING METHODS:
  # def create_shop_for_user
  #   return if shop.present?
  #   create_shop!(name: "#{name}'s Shop", description: "Shop for #{name}")
  # rescue => e
  #   Rails.logger.error "🚨 Failed to auto-create shop: #{e.message}"
  # end

  # def create_profile_for_user
  #   create_profile(profile_picture: 'default.png')  # ← THIS CAUSES THE ERROR!
  # end

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