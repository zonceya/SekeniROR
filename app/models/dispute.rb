class Dispute < ApplicationRecord
  belongs_to :order
  belongs_to :user
  belongs_to :admin_user, optional: true

  validates :reason, presence: true
  validates :status, presence: true

  enum status: {
    opened: 0,
    under_review: 1,
    resolved: 2,
    closed: 3
  }

  serialize :evidence_photos, coder: YAML
end
