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
      order_items.each do |order_item|
        order_item.item.with_lock do
          if hold
            # For held items, just reduce the reserved count
            order_item.item.decrement!(:reserved, order_item.quantity)
          else
            # For non-held items, reduce both quantity and reserved
            order_item.item.decrement!(:quantity, order_item.quantity)
            order_item.item.decrement!(:reserved, order_item.quantity)
          end
        end
      end
    elsif order_status_previously_was == 'paid' && order_cancelled?
      order_items.each do |order_item|
        next if hold # Don't return inventory for held items that were completed
        
        order_item.item.with_lock do
          order_item.item.increment!(:quantity, order_item.quantity)
        end
      end
    end
  end

  private

  def calculate_total_price
    self.total_price = actual_price * quantity
  end
end