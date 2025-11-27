# app/models/seller_strike.rb
class SellerStrike < ApplicationRecord
  belongs_to :seller, class_name: 'User'

  enum :severity, { low: 'low', medium: 'medium', high: 'high' }
  enum :status, { active: 'active', expired: 'expired' }

  validates :reason, presence: true
end