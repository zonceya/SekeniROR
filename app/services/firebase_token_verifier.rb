require 'jwt'
require 'net/http'
require 'json'

class FirebaseTokenVerifier
  class InvalidTokenError < StandardError; end
  
  def self.verify(id_token)
    new.verify(id_token)
  end
  
  def verify(id_token)
    return nil if id_token.blank?
    
    # Load Firebase config
    firebase_config = load_firebase_config
    project_id = firebase_config['project_id']
    
    begin
      # Decode token without verification to get key ID
      unverified = JWT.decode(id_token, nil, false)
      kid = unverified[1]['kid']
      
      # Get public keys (cached)
      certs = get_public_keys
      
      return nil unless certs && certs[kid]
      
      public_key = OpenSSL::X509::Certificate.new(certs[kid]).public_key
      
      # Verify the token
      decoded = JWT.decode(id_token, public_key, true, {
        algorithm: 'RS256',
        iss: "https://securetoken.google.com/#{project_id}",
        aud: project_id,
        verify_iss: true,
        verify_aud: true,
        verify_expiration: true
      })
      
      payload = decoded[0]
      
      {
        uid: payload['sub'],
        email: payload['email'],
        email_verified: payload['email_verified'],
        name: payload['name'],
        picture: payload['picture']
      }
    rescue => e
      Rails.logger.error "Firebase token verification failed: #{e.message}"
      nil
    end
  end
  
  private
  
  def load_firebase_config
    config_path = Rails.root.join('config/firebase-service-account.json')
    
    unless File.exist?(config_path)
      Rails.logger.error "Firebase service account JSON not found at #{config_path}"
      # Return default for development
      return { 'project_id' => 'skoolswap-7e387' }
    end
    
    JSON.parse(File.read(config_path))
  end
  
  def get_public_keys
    # Cache the keys for 24 hours
    Rails.cache.fetch('firebase_public_keys', expires_in: 24.hours) do
      url = URI('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com')
      
      # Use Net::HTTP with SSL verification disabled for Windows
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE  # Skip SSL verification for Windows
      http.open_timeout = 10
      http.read_timeout = 10
      
      request = Net::HTTP::Get.new(url)
      response = http.request(request)
      
      if response.code == '200'
        JSON.parse(response.body)
      else
        Rails.logger.error "Failed to fetch Firebase public keys: #{response.code}"
        {}
      end
    end
  rescue => e
    Rails.logger.error "Error fetching public keys: #{e.message}"
    {}
  end
end