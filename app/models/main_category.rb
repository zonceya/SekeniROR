class MainCategory < ApplicationRecord
  # Associations
  has_many :sub_categories, dependent: :destroy
  has_many :item_types
  has_many :items
  
  # Validations
  validates :name, presence: true, uniqueness: true
  
  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(display_order: :asc, id: :asc) }
  
  # Callbacks
  before_destroy :check_for_dependencies
  
  private
  
  def check_for_dependencies
    if items.any? || item_types.any?
      errors.add(:base, "Cannot delete category with associated items or item types")
      throw :abort
    end
  end
end