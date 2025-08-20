class ReturnRequest < ApplicationRecord
  belongs_to :order_item
  
  # Validations
  validates :order_item_id, presence: true
  validates :reason, presence: true
  validates :status, presence: true, inclusion: { in: ['pending', 'approved', 'rejected', 'processed'] }
  
  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
  
  # Methods
  def approve!
    update(status: 'approved')
  end
  
  def reject!
    update(status: 'rejected')
  end
end