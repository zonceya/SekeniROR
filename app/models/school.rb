# app/models/school.rb
class School < ApplicationRecord
  # REMOVE these lines - they don't match your database:
  # belongs_to :town
  # has_one :province, through: :town
  
  # ADD this instead:
  belongs_to :province
  
  # Scopes for filtering
  scope :by_province, ->(province_id) { 
    where(province_id: province_id) 
  }
  
  scope :search, ->(query) { 
    where('name ILIKE ?', "%#{query}%") 
  }
  
  scope :nearby_for_user, ->(user) {
    return none unless user&.location_id
    
    user_location = Location.find(user.location_id)
    where(province_id: user_location.town.province_id)
  }
end