class ItemVariant < ApplicationRecord
  belongs_to :item
  belongs_to :color, class_name: 'ItemColor', optional: true
  belongs_to :size, class_name: 'ItemSize', optional: true
belongs_to :condition, class_name: 'ItemCondition', optional: true
  validates :item_id, presence: true
  
  # Optional: Add any additional validations or methods
  def display_name
    variant_name.present? ? "#{variant_name}: #{variant_value}" : "Variant ##{id}"
  end
end