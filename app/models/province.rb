# app/models/province.rb
class Province < ApplicationRecord
  # Associations
  has_many :towns
  has_many :locations
  has_many :schools
  
  # Validations
  validates :name, presence: true
  validates :code, presence: true, uniqueness: true, allow_nil: true
  
  # Scopes
  scope :active, -> { where(active: true) }
end