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

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  enum :status, { inactive: 0, active: 1, sold: 2, archived: 3 }, default: :active

  store_accessor :meta, :color, :size
end