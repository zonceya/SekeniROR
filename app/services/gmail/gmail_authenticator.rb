# app/services/gmail_authenticator.rb
class GmailAuthenticator
  def self.authenticate
    oauth_config = Rails.application.credentials.installed
    
    client_id = Google::Auth::ClientId.new(
      oauth_config[:client_id],
      oauth_config[:client_secret]
    )
    
    token_store = Google::Auth::Stores::FileToken.new(Rails.root.join('config', 'gmail_token.yml'))
    authorizer = Google::Auth::UserAuthorizer.new(
      client_id,
      [Google::Apis::GmailV1::AUTH_GMAIL_READONLY],
      token_store
    )
    
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    
    if credentials
      return credentials
    else
      # Get authorization URL
      url = authorizer.get_authorization_url(base_url: 'urn:ietf:wg:oauth:2.0:oob')
      puts "🔐 Please visit this URL to authorize Gmail access:"
      puts url
      puts ""
      puts "After authorizing, enter the code you get:"
      
      code = gets.chomp
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id,
        code: code,
        base_url: 'urn:ietf:wg:oauth:2.0:oob'
      )
      
      return credentials
    end
  end
end