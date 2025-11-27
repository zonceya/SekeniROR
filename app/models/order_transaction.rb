# app/models/order_transaction.rb
class OrderTransaction < ApplicationRecord
  belongs_to :order

  enum :txn_status, {
    pending: 1,
    received: 2, 
    flagged: 3
  }, prefix: :txn

  enum :payment_method, {
    eft: 1,
    card: 2,
    wallet: 3
  }, prefix: :method

  validates :order_id, :amount, presence: true
  validates :amount, numericality: { greater_than: 0 }
end