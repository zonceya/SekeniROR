class Order < ApplicationRecord
  before_validation :assign_order_number, on: :create
  after_update :update_inventory, if: :saved_change_to_order_status?
  after_update :create_payment_notifications, if: :payment_status_changed_to_paid?
  enum :order_status, {
    pending: 0,
    paid: 1,
    processing: 2,
    dispatched: 3,
    shipped: 4,
    delivered: 5,
    completed: 6,
    disputed: 7,
    cancelled: 8
  }, prefix: :order, default: :pending

  enum :payment_status, {
    unpaid: 0,
    processing: 1,
    paid: 2,
    refunded: 3,
    awaiting_verification: 4,
    amount_mismatch: 5,
    expired: 6 
  }, prefix: :payment, default: :unpaid

  # Associations
  belongs_to :buyer, class_name: 'User'
  belongs_to :shop
  has_many :order_items, dependent: :destroy, inverse_of: :order
  has_many :notifications, as: :notifiable
  accepts_nested_attributes_for :order_items
  attribute :payment_initiated_at, :datetime
  attribute :payment_expires_at, :datetime
  
  # Validations
  validates :shop_id, :buyer_id, :price, :total_amount, presence: true
  validates :price, :service_fee, :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :addresses_format
  validates :order_number, presence: true, uniqueness: true, length: { maximum: 20 }
  has_one :hold

  # Public Status Interface
  def status
    order_status
  end

  def status=(value)
    self.order_status = value
  end
  def payment_expired?
    payment_processing? && payment_expires_at && payment_expires_at.past?
  end

  def payment_time_remaining
    return 0 unless payment_processing? && payment_expires_at
    remaining = (payment_expires_at - Time.current).to_i
    [remaining, 0].max
  end
  def status_label
    order_status
  end

  def may_initiate_payment?
  order_pending? && 
  payment_unpaid? && 
  holds.any? && 
  holds.all? { |hold| hold.status_awaiting_payment? } &&
  holds.all? { |hold| !hold.expired? }
 end

  # Generate status_? methods
  Order.order_statuses.each_key do |status|
    define_method("status_#{status}?") do
      order_status == status.to_s
    end
  end

  def has_active_holds?
    holds.any? && holds.all? { |hold| hold.active? }
  end
  # Address Methods
  def may_update_address?
    order_pending? || order_paid? || order_processing?
  end

  def may_cancel?
    order_pending? && payment_unpaid?
  end

  def update_addresses(address_params)
    transaction do
      update_shipping_address(address_params[:shipping_address]) if address_params[:shipping_address]
      update_billing_address(address_params[:billing_address]) if address_params[:billing_address]
      save!
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  # Cache
  def cache_version
    updated_at.to_i
  end
  def cleanup_expired_payments
  where("created_at < ? AND payment_status = ?", 48.hours.ago, :pending)
    .update_all(payment_status: :expired)
  end

  def payment_issues?
    [:awaiting_verification, :amount_mismatch].include?(payment_status.to_sym)
  end
  private
   def payment_status_changed_to_paid?
    saved_change_to_payment_status? && payment_paid?
  end  
  def create_payment_notifications
    # Create buyer notification
    Notification.create!(
      user: buyer,
      notifiable: self,
      title: "Payment Confirmed ✅",
      message: "✅ Payment received! You can now arrange collection with the seller.",
      notification_type: 'payment_confirmation',
      status: 'pending'
    )
    
    # Create seller notification
    Notification.create!(
      user: shop.user,
      notifiable: self,
      title: "Payment Received 💰",
      message: "💰 Buyer's payment confirmed. Please arrange delivery or collection.",
      notification_type: 'payment_received',
      status: 'pending'
    )
    
    Rails.logger.info "🎯 Payment notifications created for order #{order_number}"
  end  
  def update_inventory
    if order_status_previously_was == 'pending' && order_paid?
      # When order is paid, convert reserved to actual sold inventory
      order_items.each do |item|
        item.item.with_lock do
          item.item.quantity -= item.quantity
          item.item.reserved -= item.quantity
          item.item.save!
        end
      end
    elsif order_status_previously_was == 'paid' && order_cancelled?
      # If cancelling after payment, return inventory
      order_items.each do |item|
        item.item.with_lock do
          item.item.quantity += item.quantity
          item.item.save!
        end
      end
    end
  end
      
  def assign_order_number
  shop_code = shop.name[0..3].upcase
  time_code = Time.current.strftime("%m%d%H%M%S")
  random_suffix = SecureRandom.alphanumeric(2).upcase
  self.order_number = "#{shop_code}#{time_code}#{random_suffix}"
  end

  def update_shipping_address(address)
    return if address.blank?
    self.shipping_address = (shipping_address || {}).merge(address.compact)
  end

  def update_billing_address(address)
    if address[:same_as_shipping].to_s == 'true'
      self.billing_address = { same_as_shipping: true }
    else
      self.billing_address = (billing_address || {}).merge(address.except(:same_as_shipping).compact)
    end
  end

  def addresses_format
    validate_address_format(:shipping_address)
    validate_address_format(:billing_address) if billing_address.present?
  end

  def validate_address_format(field)
    return if self[field].nil?
    unless self[field].is_a?(Hash)
      errors.add(field, "must be a JSON object")
    end
  end  

  
  # app/models/order.rb
  def process_refund(amount, reason, processed_by)
    ActiveRecord::Base.transaction do
      # Create refund transaction (negative amount)
      order_transactions.create!(
        amount: -amount,
        txn_status: :received,
        payment_method: :eft,
        meta: { 
          reason: reason,
          processed_by: processed_by.id,
          refund_date: Time.current
        }
      )
      
      # Update order status if full refund
      if amount == total_amount
        update!(payment_status: :refunded)
      end
    end
  end
  
end