class Rating < ApplicationRecord
  # Tell Rails to use the correct table name (rating instead of ratings)
  self.table_name = 'rating'
  
  belongs_to :shop
  
  # Validations
  validates :shop_id, presence: true
  validates :rating, numericality: { in: 0..5 }
  validates :user_count, numericality: { greater_than_or_equal_to: 0 }
end