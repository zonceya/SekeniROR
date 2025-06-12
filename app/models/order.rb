class Order < ApplicationRecord
  
   after_update :update_inventory, if: :saved_change_to_order_status?
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
    refunded: 3
  }, prefix: :payment, default: :unpaid

  # Associations
  belongs_to :buyer, class_name: 'User'
  belongs_to :shop
  has_many :order_items, dependent: :destroy, inverse_of: :order
  accepts_nested_attributes_for :order_items

  # Validations
  validates :shop_id, :buyer_id, :price, :total_amount, presence: true
  validates :price, :service_fee, :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :addresses_format

  # Public Status Interface
  def status
    order_status
  end

  def status=(value)
    self.order_status = value
  end

  def status_label
    order_status
  end

  # Generate status_? methods
 Order.order_statuses.each_key do |status|
  define_method("status_#{status}?") do
    order_status == status.to_s
  end
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

  private
      
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
end
