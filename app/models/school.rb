# app/models/school.rb
class School < ApplicationRecord
  belongs_to :province
  belongs_to :location 
  
  # Associations
  has_many :user_schools
  has_many :users, through: :user_schools
  
  # Scopes for filtering
  scope :by_province, ->(province_id) { 
    where(province_id: province_id) if province_id.present?
  }
  
  # Optimized search scope with minimum length requirement
  scope :search_by_name, ->(query) {
    return none if query.blank? || query.length < 2
    where('name ILIKE ?', "%#{query}%")
  }
  
  # Keep original search for compatibility
  scope :search, ->(query) { 
    return none if query.blank?
    where('name ILIKE ?', "%#{query}%") 
  }
  
  # Search with relevance ordering
  scope :search_with_relevance, ->(query) {
    return none if query.blank? || query.length < 2
    
    # Search with relevance ordering (exact match first, then starts with, then contains)
    sanitized_query = connection.quote_string(query)
    
    where('name ILIKE ?', "%#{sanitized_query}%")
      .order(Arel.sql("
        CASE 
          WHEN LOWER(name) = LOWER('#{sanitized_query}') THEN 0
          WHEN LOWER(name) LIKE '#{sanitized_query.downcase}%' THEN 1
          WHEN LOWER(name) LIKE '% #{sanitized_query.downcase}%' THEN 2
          ELSE 3
        END,
        name
      "))
  }
  
  scope :nearby_for_user, ->(user) {
    return none unless user&.location_id
    
    user_location = Location.find(user.location_id)
    where(province_id: user_location.town.province_id)
  }
  
  # Instance methods
  def full_address
    return "Unknown location" unless location&.town
    "#{location.town.name}, #{location.province}, #{location.country}"
  end
  
  def town
    location&.town
  end
  
  # Helper method for search suggestions
  def self.search_suggestions(query, limit: 5)
    return [] if query.blank? || query.length < 2
    
    search_by_name(query)
      .limit(limit)
      .pluck(:name)
  end
  
  # Get schools with pagination
  def self.paginated_search(province_id: nil, query: nil, page: 1, per_page: 20)
    schools = by_province(province_id)
    schools = schools.search_by_name(query) if query.present?
    
    total_count = schools.count
    schools = schools.order(:name)
                    .offset((page - 1) * per_page)
                    .limit(per_page)
    
    {
      schools: schools,
      total_count: total_count,
      page: page,
      per_page: per_page,
      total_pages: (total_count.to_f / per_page).ceil
    }
  end
end