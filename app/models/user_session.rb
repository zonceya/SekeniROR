class UserSession < ApplicationRecord
  belongs_to :user

  # Set expiration on creation
  before_create :set_expires_at

  def expired?
    expires_at.present? ? expires_at.past? : created_at < 30.days.ago
  end

  private

  def set_expires_at
    self.expires_at = 30.days.from_now
  end
end