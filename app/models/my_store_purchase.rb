class MyStorePurchase < ApplicationRecord
  belongs_to :shop
  
  # Validations
  validates :shop_id, presence: true
  validates :pending_orders, numericality: { greater_than_or_equal_to: 0 }
  validates :completed_orders, numericality: { greater_than_or_equal_to: 0 }
  validates :canceled_orders, numericality: { greater_than_or_equal_to: 0 }
  validates :item_count, numericality: { greater_than_or_equal_to: 0 }
  validates :revenue, numericality: { greater_than_or_equal_to: 0 }
end