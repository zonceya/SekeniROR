class Hold < ApplicationRecord
  # Status constants
  STATUSES = {
    awaiting_payment: "awaiting_payment",
    completed: "completed",
    expired: "expired",
    cancelled: "cancelled"
  }.freeze

  # Set default value
  attribute :status, :string, default: STATUSES[:awaiting_payment]

  # Define enum with correct Rails 8.0.1 syntax
  enum :status, STATUSES, 
    default: STATUSES[:awaiting_payment],
    prefix: true,   # Note: without underscore
    suffix: false   # Explicitly disable suffix

  # Create clean aliases for the prefixed methods
  STATUSES.each_key do |state|
    alias_method "#{state}?", "status_#{state}?"
    alias_method "#{state}!", "status_#{state}!"
  end

  # Validations
  validates :status, inclusion: { in: STATUSES.values }
  validates :quantity, numericality: { greater_than: 0 }
  validates :expires_at, presence: true

  # Associations
  belongs_to :item
  belongs_to :user
  belongs_to :order, optional: true

  # Scopes
  scope :awaiting_payment, -> { where(status: STATUSES[:awaiting_payment]) }
  scope :expired, -> { awaiting_payment.where("expires_at < ?", Time.current) }
  
  def complete!(order)
    return if status_completed? # Already completed
    
    ActiveRecord::Base.transaction do
      update!(
        status: :completed,
        order_id: order.id
      )
      
      # Only complete the order if payment is received
      if order.payment_paid?
        order.update!(order_status: :processing) 
      end
    end
  end
  # Instance Methods
def expire!
  return if status_expired?

  ActiveRecord::Base.transaction do
    update!(status: :expired)
    Inventory::HoldReleaseService.new(self).call
  item.with_lock do
      item.decrement!(:reserved, quantity)
    end
    if order
      order.update!(
        cancelled_at: Time.current,
        cancellation_reason: "Hold expired"
      )
    end
  end
end



  private

  def release_inventory
    item.with_lock do
      item.decrement!(:reserved, quantity)
    end
  end

 def cancel_associated_order
  return unless order

  order.status = :cancelled
  # Only save if validations will pass
  if order.valid?
    order.save!
  else
    Rails.logger.error("[ExpireHoldsJob] Failed to cancel order #{order.id}: #{order.errors.full_messages}")
  end
end

end