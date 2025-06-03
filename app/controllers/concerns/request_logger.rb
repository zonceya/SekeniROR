# app/controllers/concerns/request_logger.rb
module RequestLogger
  extend ActiveSupport::Concern

  included do
    around_action :log_request_response
  end

  private

  def log_request_response
    start_time = Time.current
    request_body = request.raw_post
    headers = filtered_headers(request.headers)

    yield

    log_entry(
      method: request.request_method,
      path: request.fullpath,
      headers: headers,
      body: request_body,
      response: response.body,
      user_id: current_user_id,
      start_time: start_time
    )
  rescue => e
    Rails.logger.error "Logging failed: #{e.message}"
    raise e unless Rails.env.production?
  end

  def filtered_headers(headers)
    headers.env
      .select { |k, _| k.start_with?('HTTP_') || %w[CONTENT_TYPE CONTENT_LENGTH].include?(k) }
      .transform_keys { |k| k.sub(/^HTTP_/, '').titleize.gsub(' ', '-') }
      .except('Authorization')
  end

  def current_user_id
    defined?(@current_user) && @current_user&.id
  end

  def log_entry(method:, path:, headers:, body:, response:, user_id:, start_time:)
    ApplicationLog.create(
      request_type: method,
      endpoint_url: path,
      request_header: headers.to_json,
      request_object: body.presence || '{}',
      response_object: response.presence || '{}',
      user_id: user_id,
      created_at: start_time,
      updated_at: Time.current
    )
  end
  def filter_sensitive_data(data)
  data.gsub(/"password":".*?"/, '"password":"[FILTERED]"')
      .gsub(/"token":".*?"/, '"token":"[FILTERED]"')
end
end