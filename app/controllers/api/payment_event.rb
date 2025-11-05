# app/models/payment_event.rb
class PaymentEvent < ApplicationRecord
  belongs_to :order
  
  enum event_type: {
    payment_initiated: 0,
    payment_expired: 1,
    payment_verified: 2,
    payment_failed: 3,
    proof_uploaded: 4
  }
  
  enum status: {
    pending: 0,
    completed: 1,
    failed: 2
  }
end