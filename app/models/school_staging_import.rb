# app/models/school_staging_import.rb
class SchoolStagingImport < ApplicationRecord
  validates :nat_emis, presence: true, uniqueness: true
  validates :province, presence: true
  
  # Resolve locality using priority: Township_Village > Suburb > Town_City
  def resolve_locality
    [township_village, suburb, town_city].each do |field|
      next if field.blank?
      cleaned = field.strip
      next if cleaned == "99"
      return cleaned
    end
    nil  # Will become "Unallocated"
  end
  
  # Check if a field is blank or placeholder
  def blank_or_placeholder?(value)
    value.blank? || value.strip == "99"
  end
  
  # Get the province record
  def province_record
    @province_record ||= Province.find_by(code: province)
  end
end