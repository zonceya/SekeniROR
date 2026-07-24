# app/models/town.rb
class Town < ApplicationRecord
  belongs_to :province
  has_many :locations
  has_many :schools, through: :locations  # <-- ADD THIS LINE
  
  def school_count
    schools.count
  end
end