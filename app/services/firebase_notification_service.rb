# app/services/firebase_notification_service.rb
class FirebaseNotificationService
  FIREBASE_V1_URL = "https://fcm.googleapis.com/v1/projects/sekeni-1a0fd/messages:send"

  class << self
    def deliver(notification)
      return unless should_deliver?
      
      user = notification.user
      return unless user.firebase_token.present?

      access_token = get_access_token
      return unless access_token

      payload = build_v1_payload(notification, user.firebase_token)
      response = send_v1_request(access_token, payload)
      
      handle_response(notification, response)
    rescue StandardError => e
      handle_delivery_error(notification, e)
    end

    private

    def should_deliver?
      Rails.env.production? || ENV['SEND_FIREBASE_NOTIFICATIONS'] == 'true'
    end

    def get_access_token
      credentials_path = Rails.root.join('config', 'firebase-service-account.json')
      
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(credentials_path),
        scope: 'https://www.googleapis.com/auth/firebase.messaging'
      )
      
      authorizer.fetch_access_token!['access_token']
    rescue StandardError => e
      Rails.logger.error "❌ Failed to get access token: #{e.message}"
      nil
    end

    def build_v1_payload(notification, token)
      {
        message: {
          token: token,
          notification: {
            title: notification.title,
            body: notification.message
          },
          data: {
            notification_id: notification.id.to_s,
            order_id: notification.notifiable_id.to_s,
            notifiable_type: notification.notifiable_type,
            type: notification.notification_type,
            click_action: "FLUTTER_NOTIFICATION_CLICK"
          },
          android: {
            priority: "high"
          },
          apns: {
            headers: {
              "apns-priority": "10"
            },
            payload: {
              aps: {
                sound: "default"
              }
            }
          }
        }
      }
    end

    def send_v1_request(access_token, payload)
      require 'net/http'
      require 'uri'
      
      uri = URI.parse(FIREBASE_V1_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 15
      
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{access_token}"
      request['Content-Type'] = 'application/json'
      request.body = payload.to_json
      
      response = http.request(request)
      
      # Convert to simple response format
      {
        code: response.code.to_i,
        body: response.body,
        success: response.code.start_with?('2')
      }
    end

    def handle_response(notification, response)
      if response[:success]
        notification.update!(
          status: 'delivered',
          firebase_sent: true,
          delivered_at: Time.current,
          firebase_response: response[:body]
        )
        Rails.logger.info "✅ FCM V1 notification delivered: #{notification.id}"
      else
        notification.update!(
          status: 'failed',
          firebase_response: response[:body]
        )
        Rails.logger.error "❌ FCM V1 delivery failed: #{response[:code]} - #{response[:body]}"
      end
    end

    def handle_delivery_error(notification, error)
      notification.update!(
        status: 'failed',
        firebase_response: error.message
      )
      Rails.logger.error "❌ FCM V1 delivery error: #{error.message}"
    end
  end
end