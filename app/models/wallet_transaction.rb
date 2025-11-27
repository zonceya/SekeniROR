# app/models/wallet_transaction.rb
class WalletTransaction < ApplicationRecord
  belongs_to :digital_wallet, foreign_key: 'digital_wallet_id'
  belongs_to :order, foreign_key: 'order_id', optional: true
  belongs_to :transfer_request, foreign_key: 'transfer_request_id', optional: true

  # CORRECT enum syntax
  enum :transaction_type, { credit: 'credit', debit: 'debit' }
  enum :status, { pending: 'pending', completed: 'completed', failed: 'failed', refunded: 'refunded' }
  enum :transaction_source, { 
    order_payment: 'order_payment', 
    bank_transfer: 'bank_transfer', 
    admin_topup: 'admin_topup', 
    service_fee: 'service_fee', 
    insurance_fee: 'insurance_fee', 
    refund: 'refund' 
  }

  validates :amount, :transaction_type, :status, :transaction_source, presence: true
  validates :amount, numericality: { greater_than: 0 }

  before_save :calculate_net_amount

  def calculate_net_amount
    self.net_amount = transaction_type == 'credit' ? amount : -amount
    self.net_amount -= service_fee if service_fee
    self.net_amount -= insurance_fee if insurance_fee
  end

  def description
    case transaction_source
    when 'order_payment'
      "Payment for Order ##{order&.order_number}"
    when 'bank_transfer'
      "Bank transfer to #{transfer_request&.bank_account&.bank_name}"
    when 'admin_topup'
      "Wallet top-up"
    when 'service_fee'
      "Service fee for Order ##{order&.order_number}"
    when 'insurance_fee'
      "Insurance fee for Order ##{order&.order_number}"
    when 'refund'
      "Refund for Order ##{order&.order_number}"
    else
      "Wallet transaction"
    end
  end
end