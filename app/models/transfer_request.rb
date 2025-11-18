# app/models/transfer_request.rb
class TransferRequest < ApplicationRecord
  belongs_to :digital_wallet, foreign_key: 'digital_wallet_id'
  belongs_to :bank_account, foreign_key: 'bank_account_id'
  has_one :wallet_transaction, dependent: :destroy, foreign_key: 'transfer_request_id'

  # CORRECT enum syntax - remove parentheses and use symbol syntax
  enum :status, { 
    pending: 'pending', 
    processing: 'processing', 
    completed: 'completed', 
    failed: 'failed' 
  }

  validates :amount, numericality: { greater_than: 0 }
  validate :sufficient_balance

  before_create :generate_reference
  after_create :create_debit_transaction

  def sufficient_balance
    return unless digital_wallet && amount.present?
    
    if amount > digital_wallet.available_balance
      errors.add(:amount, "insufficient balance. Available: R#{digital_wallet.available_balance}")
    end
  end

  def generate_reference
    self.reference ||= "TFR#{SecureRandom.hex(6).upcase}"
  end

  def create_debit_transaction
    wallet_transaction = digital_wallet.wallet_transactions.create!(
      amount: amount,
      transaction_type: 'debit',
      status: 'pending',
      transaction_source: 'bank_transfer',
      description: "Bank transfer to #{bank_account.bank_name}",
      transfer_request_id: id
    )
  end
end