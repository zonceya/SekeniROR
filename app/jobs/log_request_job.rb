class LogRequestJob < ApplicationJob
  queue_as :default
  
  MAX_RESPONSE_LENGTH = 1000
  MAX_REQUEST_LENGTH = 500
  
  def perform(request_type:, endpoint_url:, request_header:, request_object:, response_object:, status:, user_id:, duration_ms: nil)
    start_time = Time.current
    
    # Skip logging for heavy read endpoints that cause delays
    if should_skip_logging?(endpoint_url)
      Rails.logger.info("Skipped logging for heavy endpoint: #{endpoint_url}")
      return
    end
    
    # Sanitize headers - remove sensitive information
    sanitized_headers = sanitize_headers(request_header)
    
    # Truncate response object if too large
    safe_response_object = truncate_response(response_object)
    
    # Calculate duration if not provided
    final_duration = duration_ms || ((Time.current - start_time) * 1000).round(2)
    
    ApplicationLog.create!(
      request_type: request_type,
      endpoint_url: endpoint_url,
      user_id: user_id,
      status: status,
      duration_ms: final_duration,
      request_header: sanitized_headers,
      request_object: truncate_request(request_object),
      response_object: safe_response_object,
      created_at: Time.current
    )
  rescue => e
    # Fail silently - don't let logging errors affect main request
    Rails.logger.error("Failed to create application log: #{e.message}")
  end
  
  private
  
  def should_skip_logging?(url)
    heavy_patterns = [
      '/recommendations/home',
      '/recommendations/recommended/all',
      '/api/v1/home_feed',
      '/filters/global_config',
      '/user_schools/current'
    ]
    heavy_patterns.any? { |pattern| url.include?(pattern) }
  end
  
  def sanitize_headers(headers)
    return nil unless headers.present?
    
    # Remove sensitive headers
    filtered_headers = headers.dup
    filtered_headers.delete('HTTP_AUTHORIZATION')
    filtered_headers.delete('Authorization')
    filtered_headers.delete('X-API-Key')
    filtered_headers.delete('Cookie')
    
    filtered_headers.to_json
  rescue
    nil
  end
  
  def truncate_response(response)
    return nil unless response.present?
    
    response_string = response.to_s
    if response_string.length > MAX_RESPONSE_LENGTH
      return "#{response_string[0..MAX_RESPONSE_LENGTH]}... [TRUNCATED - #{response_string.length} bytes]"
    end
    response_string
  rescue
    nil
  end
  
  def truncate_request(request)
    return nil unless request.present?
    
    request_string = request.to_s
    request_string.length > MAX_REQUEST_LENGTH ? request_string[0..MAX_REQUEST_LENGTH] : request_string
  rescue
    nil
  end
end