# app/jobs/log_request_job.rb
class LogRequestJob < ApplicationJob
  def perform(params)
    ApplicationLog.create!(
      request_type: params[:request_type],
      endpoint_url: params[:endpoint_url],
      request_header: params[:request_header],
      request_object: params[:request_object],
      response_object: params[:response_object],
       status: params[:status], # Map to your status column
      user_id: params[:user_id]
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to log request: #{e.message}"
  end
end