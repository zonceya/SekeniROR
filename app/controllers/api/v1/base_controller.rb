class Api::V1::BaseController < ApplicationController
    include Authenticatable  # your auth concern
    include RequestLogger
    around_action :log_request_response
    protect_from_forgery with: :null_session
    private
  
    def log_request_response
      # Capture request details before action
      request_body = request.raw_post
      headers = request.headers.env.select { |k, v| k.start_with?('HTTP_') }
      start_time = Time.now
  
      yield  # execute controller action
  
      # Capture response details after action
      response_body = response.body
      user_id = @current_user&.id
  
      ApplicationLog.create(
        request_type: request.request_method,
        endpoint_url: request.fullpath,
        request_header: headers.to_json,
        request_object: request_body,
        response_object: response_body,
        user_id: user_id,
        date: start_time
      )
    rescue => e
      Rails.logger.error "Failed to log application request: #{e.message}"
    end
  end
  