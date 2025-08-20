class Promotion < ApplicationRecord
  belongs_to :item, optional: true
  belongs_to :shop
  
  # Validations
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :shop_id, presence: true
  validates :title, presence: true
  
  # Custom validation to ensure end_date is after start_date
  validate :end_date_after_start_date
  
  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :current, -> { where('start_date <= ? AND end_date >= ?', Time.current, Time.current) }
  
  private
  
  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    
    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end