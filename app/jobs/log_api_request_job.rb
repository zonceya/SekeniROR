class LogApiRequestJob < ApplicationJob
  queue_as :default

  def perform(params)
    ApplicationLog.create(
      request_type: params[:request_type],
      endpoint_url: params[:endpoint_url],
      request_header: params[:request_header],
      request_object: params[:request_object],
      response_object: params[:response_object],
      date: Time.current,
      user_id: params[:user_id],
      date: params[:date]
    )
  end
end
