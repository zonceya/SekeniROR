class PurchaseHistory < ApplicationRecord
  # Tell Rails to use the correct table name
  self.table_name = 'purchase_history'
  
  belongs_to :user
  belongs_to :item
  
  # Validations
  validates :user_id, presence: true
  validates :item_id, presence: true
  
  # Scopes or methods if needed
  scope :recent, -> { order(purchased_at: :desc) }
end