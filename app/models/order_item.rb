class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :item
  belongs_to :item_variant, optional: true
  belongs_to :shop

  validates :actual_price, :total_price, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  before_save :calculate_total_price

  private

  def calculate_total_price
    self.total_price = actual_price * quantity
  end
end