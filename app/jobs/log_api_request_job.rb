class LogApiRequestJob < ApplicationJob
  queue_as :default

  def perform(params)
    ApplicationLog.create(
      request_type: params[:request_type],
      endpoint_url: params[:endpoint_url],
      request_header: params[:request_header],
      request_object: params[:request_object],
      response_object: params[:response_object],
      logged_at: Time.current,  # Changed from 'date' to 'logged_at'
      user_id: params[:user_id],
      requested_at: params[:date]  # Changed from 'date' to 'requested_at'
    )
  end
end
