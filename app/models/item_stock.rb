class ItemStock < ApplicationRecord
  self.table_name = 'item_stock'  # Explicitly set the table name

  belongs_to :item_variant, foreign_key: 'item_variant_id', optional: true
  belongs_to :location, optional: true
  belongs_to :condition, class_name: 'ItemCondition', foreign_key: 'condition_id', optional: true

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }

  def in_stock?
    quantity.to_i > 0
  end
end