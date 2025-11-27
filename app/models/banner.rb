# app/models/banner.rb
class Banner < ApplicationRecord
  # Banner types
  BANNER_TYPES = %w[home school brand sale category promotion].freeze
  TARGET_TYPES = %w[school brand promotion category item].freeze
  
  # Validations
  validates :title, :image_url, presence: true
  validates :banner_type, inclusion: { in: BANNER_TYPES }
  validates :target_type, inclusion: { in: TARGET_TYPES }, allow_nil: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

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