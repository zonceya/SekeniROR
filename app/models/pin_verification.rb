class PinVerification < ApplicationRecord
  belongs_to :order
  belongs_to :buyer, class_name: 'User'
  belongs_to :seller, class_name: 'User'

  validates :pin_code, presence: true

  # Rails 8.0 enum syntax
  enum :status, {
    active: 'active',
    pending: 'pending',
    verified: 'verified', 
    expired: 'expired',
    cancelled: 'cancelled'
  }
  
  before_validation :ensure_pin_code, on: :create
  before_validation :ensure_expiration, on: :create

  scope :active, -> { where(status: ['pending', 'active']) }

  def active?
    (status == 'pending' || status == 'active') && !expired?
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def update_status_based_on_time
    if expired? && (pending? || active?)
      update(status: :expired)
    end
  end

  def verify!(entered_pin)
    return false unless active?
    return false unless pin_code == entered_pin

    update!(
      status: :verified,
      verified_at: Time.current
    )
    
    # Update order status after successful verification
    order.update!(order_status: 'completed') if order.respond_to?(:update!)
    true
  end

  def self.generate_for_order(order)
    create!(
      order: order,
      buyer: order.buyer,
      seller: order.shop.user,
      status: :pending
    )
  end

  private

  def ensure_pin_code
    return if pin_code.present?
    self.pin_code = SecureRandom.random_number(1000000).to_s.rjust(6, '0')
  end

  def ensure_expiration
    return if expires_at.present?
    self.expires_at = 30.minutes.from_now
  end
end