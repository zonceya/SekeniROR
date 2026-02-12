class ItemType < ApplicationRecord
  belongs_to :main_category, optional: true
  belongs_to :group, class_name: 'ItemGroup', optional: true
  
  scope :active, -> { where(is_active: true) }
  scope :by_main_category, ->(category_id) { where(main_category_id: category_id) }
  
  validates :name, presence: true, uniqueness: true
end
