
# app/models/dispute.rb
class Dispute < ApplicationRecord
  belongs_to :order
  belongs_to :raised_by, class_name: 'User'
  has_many :refunds

  enum :status, {
    under_review: 'under_review',
    resolved_buyer: 'resolved_buyer',
    resolved_seller: 'resolved_seller',
    escalated: 'escalated',
    closed: 'closed'
  }

  serialize :evidence_photos, type: Array
end
