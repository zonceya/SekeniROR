class Gender < ApplicationRecord
  # Optional: Add any model validations or associations
  validates :name, presence: true
  validates :category, presence: true
  
  # Optional scope for easy querying
  scope :standard, -> { where(category: 'standard') }
  scope :by_age, -> { where(category: 'age') }
end