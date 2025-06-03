class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  after_action :log_request
  protect_from_forgery with: :exception
  private

  def log_request
    LogRequestJob.perform_later(
      request_type: request.method,
      endpoint_url: request.fullpath,
      request_header: request.headers.env.select { |k, _| k.start_with?("HTTP_") }.to_json,
      request_object: request.request_parameters.to_json,
      response_object: response.body.to_json,
      user_id: @current_user&.id 
    )
  end
end
