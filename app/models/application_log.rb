class ApplicationLog < ApplicationRecord
  # Validations
  validates :request_type, presence: true
  validates :endpoint_url, presence: true
  # DO NOT validate presence of response_object - it's optional now!
  
  # Scopes
  scope :recent, -> { order(created_at: :desc).limit(100) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_endpoint, ->(url) { where('endpoint_url LIKE ?', "%#{url}%") }
  scope :slow_requests, -> { where('duration_ms > ?', 1000) }
  scope :failed_requests, -> { where('status >= 400') }
  scope :old, -> { where('created_at < ?', 30.days.ago) }
  
  # Cleanup old logs
  def self.cleanup_old_logs(days = 30)
    where('created_at < ?', days.days.ago).delete_all
  end
end