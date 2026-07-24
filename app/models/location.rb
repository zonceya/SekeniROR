# app/models/location.rb
class Location < ApplicationRecord
  belongs_to :town, optional: true
  has_many :schools  # <-- ADD THIS LINE
  
  has_many :items
  
  def full_location
    return "Unknown location" unless town
    "#{town.name}, #{province}, #{country}"
  end
  
  delegate :name, to: :town, prefix: true, allow_nil: true
end