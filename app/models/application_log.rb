class ApplicationLog < ApplicationRecord
    # app/models/application_log.rb
validates :request_type, :endpoint_url, presence: true
validates :response_object, presence: true
scope :recent, -> { order(created_at: :desc).limit(100) }
scope :by_user, ->(user_id) { where(user_id: user_id) }
end
