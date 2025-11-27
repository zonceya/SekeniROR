class DigitalWallet < ApplicationRecord
  belongs_to :user
  has_many :wallet_transactions, dependent: :destroy, foreign_key: 'digital_wallet_id'
  has_many :bank_accounts, dependent: :destroy, foreign_key: 'digital_wallet_id'
  has_many :transfer_requests, dependent: :destroy, foreign_key: 'digital_wallet_id'

  validates :user_id, uniqueness: true
  validates :wallet_number, presence: true, uniqueness: true

  before_validation :generate_wallet_number, on: :create

  def current_balance
    wallet_transactions.completed.sum(:net_amount)
  end

  def pending_balance
    wallet_transactions.pending.sum(:net_amount)
  end

  def available_balance
    current_balance - pending_balance.abs
  end

  private

  def generate_wallet_number
    self.wallet_number ||= "WAL#{SecureRandom.hex(8).upcase}"
  end
end