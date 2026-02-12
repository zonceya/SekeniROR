class SubCategory < ApplicationRecord
  # Associations
  belongs_to :main_category
  has_many :items
  
  # Validations
  validates :name, presence: true
  validates :main_category_id, presence: true
  validates :name, uniqueness: { scope: :main_category_id }
  
  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(display_order: :asc, id: :asc) }
  
  # Callbacks
  before_destroy :check_for_dependencies
  
  private
  
  def check_for_dependencies
    if items.any?
      errors.add(:base, "Cannot delete subcategory with associated items")
      throw :abort
    end
  end
end