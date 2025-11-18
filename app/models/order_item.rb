class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :item
  belongs_to :item_variant, optional: true
  belongs_to :shop
  belongs_to :hold, optional: true

  validates :actual_price, :total_price, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  before_save :calculate_total_price

  def update_inventory
    if order_status_previously_was == 'pending' && order_paid?
      # When order is paid, convert reserved to actual sold inventory
      # Only decrease the quantity, don't touch reserved (it was already reserved)
      order_items.each do |item|
        item.item.with_lock do
          item.item.quantity -= item.quantity
          # Don't decrease reserved here - it was already reserved during hold creation
          item.item.save!
        end
      end
    elsif order_status_previously_was == 'paid' && order_cancelled?
      # If cancelling after payment, return inventory to quantity
      order_items.each do |item|
        item.item.with_lock do
          item.item.quantity += item.quantity
          item.item.save!
        end
      end
      end
  end

  private

  def calculate_total_price
    self.total_price = actual_price * quantity
  end
end