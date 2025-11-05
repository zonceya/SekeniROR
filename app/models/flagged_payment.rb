# app/models/flagged_payment.rb
class FlaggedPayment < ApplicationRecord
  belongs_to :order, optional: true

  # CORRECT Rails 8 syntax:
  enum(:status, { 
    amount_mismatch: 'amount_mismatch',
    order_not_found: 'order_not_found', 
    manual_review: 'manual_review'
  })

  validates :reference, :received_amount, :bank, :status, presence: true
end