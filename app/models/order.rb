class Order < ApplicationRecord
  # Status Enums
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
  }, prefix: true, default: :pending

  enum :payment_status, { 
    unpaid: 0, 
    paid: 1, 
    refunded: 2 
  }, prefix: true, default: :unpaid

  # Associations
  belongs_to :buyer, class_name: 'User'
  belongs_to :shop
  has_many :order_items, dependent: :destroy, inverse_of: :order
  accepts_nested_attributes_for :order_items
  # Validations
  validates :shop_id, :buyer_id, :price, :total_amount, presence: true
  validates :price, :service_fee, :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :addresses_format

  # Scopes
  scope :active, -> { where(deleted: false) }
  scope :by_shop, ->(shop_id) { where(shop_id: shop_id) }
  scope :recent, -> { order(order_place_time: :desc) }

  # Instance Methods
  def update_addresses(address_params)
    update(
      shipping_address: address_params[:shipping_address] || shipping_address,
      billing_address: address_params[:billing_address] || billing_address
    )
  end

  def cancellable?
    order_status_pending? && payment_status_unpaid?
  end

  private

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