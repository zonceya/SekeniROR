class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_many :user_sessions, dependent: :destroy
  has_one :shop, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_secure_password validations: false # Disable default validations

  # Password validation
  validates :password, 
            presence: { if: :password_required? },
            length: { minimum: 6, allow_blank: true },
            confirmation: { if: :password_required? }

  after_commit :create_shop_for_user, on: :create
  after_create :create_profile_for_user
  before_destroy :set_logout_time

  scope :admins, -> { where(role: 'admin') }

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

  private

 def password_required?
  false
end


  def create_shop_for_user
    return if shop.present?

    create_shop!(
      name: "#{name}'s Shop",
      description: "Shop for #{name}"
    )
  rescue => e
    Rails.logger.error "🚨 Failed to auto-create shop: #{e.message}"
  end

  def create_profile_for_user
    create_profile(profile_picture: 'default.png')
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