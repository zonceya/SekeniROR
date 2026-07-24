# app/models/school.rb
class School < ApplicationRecord
  belongs_to :province
   belongs_to :location 
  # ADD THIS association
  has_many :user_schools
  has_many :users, through: :user_schools
  
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
   def full_address
    return "Unknown location" unless location&.town
    "#{location.town.name}, #{location.province}, #{location.country}"
  end
    def town
    location&.town
    end
end