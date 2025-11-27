class BankAccount < ApplicationRecord
  belongs_to :digital_wallet, foreign_key: 'digital_wallet_id'
  has_many :transfer_requests, dependent: :destroy, foreign_key: 'bank_account_id'

  validates :account_holder_name, :bank_name, :account_number, :branch_code, presence: true
  validates :account_number, uniqueness: { scope: [:bank_name, :branch_code] }

  before_validation :validate_account_number

  def masked_account_number
    "****#{account_number.last(4)}"
  end

  def display_name
    "#{bank_name} - #{masked_account_number}"
  end

  private

  def validate_account_number
    return unless account_number.present?
    
    unless account_number.match?(/\A\d{8,20}\z/)
      errors.add(:account_number, "must be between 8-20 digits")
    end
  end
end