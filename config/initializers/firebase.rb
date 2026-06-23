# config/initializers/firebase.rb
require 'json'
require 'jwt'
require 'faraday'
require 'openssl'

# Load Firebase service account config
FIREBASE_CONFIG = JSON.parse(
  File.read(Rails.root.join('config/firebase-service-account.json'))
)

def verify_firebase_token(id_token)
  return nil if id_token.blank?
  
  project_id = FIREBASE_CONFIG['project_id']
  
  begin
    # Decode token without verification to get the key ID
    unverified = JWT.decode(id_token, nil, false)
    kid = unverified[1]['kid']
    
    # Fetch Google's public keys
    cache_key = "firebase_certs_#{kid}"
    
    # Try to get from Rails cache, otherwise fetch
    certs = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      cert_url = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"
      response = Faraday.get(cert_url)
      JSON.parse(response.body)
    end
    
    # Get the public key for this kid
    certificate = OpenSSL::X509::Certificate.new(certs[kid])
    public_key = certificate.public_key
    
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
  rescue JWT::ExpiredSignature
    Rails.logger.error "Firebase token expired"
    nil
  rescue JWT::VerificationError => e
    Rails.logger.error "Firebase token verification failed: #{e.message}"
    nil
  rescue => e
    Rails.logger.error "Firebase token error: #{e.message}"
    nil
  end
end