class LogRequestJob < ApplicationJob
  queue_as :default

  def perform(request_data)
    Rails.logger.info "[LogRequestJob] Writing to application_log: #{request_data.inspect}"
    
    log_attributes = {
      request_type: request_data[:request_type],
      endpoint_url: request_data[:endpoint_url],
      request_header: request_data[:request_header],
      request_object: request_data[:request_object],
      response_object: request_data[:response_object],
      user_id: request_data[:user_id]
      # Removed created_at since it's not in your model
    }

    ApplicationLog.create!(log_attributes)
  rescue => e
    Rails.logger.error "[LogRequestJob] Failed to log request: #{e.message}"
    # Consider retrying for certain errors
    raise if e.is_a?(ActiveRecord::ConnectionTimeoutError)
  end
end