class Item < ApplicationRecord
  belongs_to :shop, optional: true
  belongs_to :item_type, optional: true
  belongs_to :item_condition, optional: true
  belongs_to :brand, optional: true
  belongs_to :school, optional: true
  belongs_to :size, class_name: 'ItemSize', optional: true
  belongs_to :location, optional: true
  belongs_to :province, optional: true
  belongs_to :gender, optional: true
  
  has_many :item_tags
  has_many :tags, through: :item_tags

  validate :non_negative_inventory
  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  enum :status, { inactive: 0, active: 1, sold: 2, archived: 3 }, default: :active

  store_accessor :meta, :color, :size
  def available_quantity
    quantity - reserved
  end
  
  def available_quantity
    quantity.to_i - reserved.to_i
  end

  def can_fulfill?(requested_quantity)
    available_quantity >= requested_quantity
  end

  private

def non_negative_inventory
  if quantity.to_i < 0
    errors.add(:quantity, "can't be negative")
  end
  if reserved.to_i < 0
    errors.add(:reserved, "can't be negative")
  end
  if reserved.to_i > quantity.to_i
    errors.add(:reserved, "can't reserve more than available quantity")
  end
end
end