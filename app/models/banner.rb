# app/models/banner.rb
class Banner < ApplicationRecord
  # Comment out Active Storage for now
  # has_one_attached :image
  
  # Banner types
  BANNER_TYPES = %w[home school brand sale category promotion].freeze
  TARGET_TYPES = %w[school brand promotion category item].freeze
  
  # Validations
  validates :title, presence: true
  validates :image_url, presence: true  # Use the existing column

  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, created_at: :desc) }

  # Methods
  def currently_active?
    active? &&
      (start_date.nil? || start_date <= Time.current) &&
      (end_date.nil? || end_date >= Time.current)
  end
end