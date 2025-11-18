class Refund < ApplicationRecord
  belongs_to :order
  belongs_to :dispute, optional: true
  belongs_to :wallet_transaction, optional: true
  belongs_to :processed_by, class_name: 'User', optional: true

  enum :status, {
    pending_review: 'pending_review',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed',
    rejected: 'rejected'
  }

  enum :refund_type, {
    buyer_cancellation: 'buyer_cancellation',
    dispute: 'dispute',
    admin_refund: 'admin_refund'
  }

  validates :amount, numericality: { greater_than: 0 }
  validates :reason, presence: true
end