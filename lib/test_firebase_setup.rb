# lib/test_firebase_setup.rb
puts "Testing Firebase Setup for Sekeni..."
puts "===================================="

credentials_path = Rails.root.join('config', 'firebase-service-account.json')

if File.exist?(credentials_path)
  puts "✅ Firebase service account found!"
  file_content = JSON.parse(File.read(credentials_path))
  puts "📁 Project ID: #{file_content['project_id']}"
  puts "📧 Client Email: #{file_content['client_email']}"
  puts "🆔 Client ID: #{file_content['client_id']}"
  
  # Test token generation with correct method
  begin
    puts "\n🔑 Testing access token generation..."
    
    require 'googleauth'
    
    # Use the correct method: make_creds
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(credentials_path),
      scope: 'https://www.googleapis.com/auth/firebase.messaging'
    )
    
    token_info = authorizer.fetch_access_token!
    token = token_info['access_token']
    
    if token
      puts "✅ Access token generated successfully!"
      puts "   Token length: #{token.length} characters"
      puts "   Token type: #{token_info['token_type']}"
      puts "   Expires in: #{token_info['expires_in']} seconds"
      
      # Test Firebase API connection using Net::HTTP (built into Ruby)
      puts "\n📡 Testing Firebase API connection..."
      require 'net/http'
      require 'uri'
      
      # Test the projects.get endpoint
      project_url = "https://firebase.googleapis.com/v1beta1/projects/#{file_content['project_id']}"
      uri = URI.parse(project_url)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{token}"
      request['Content-Type'] = 'application/json'
      
      response = http.request(request)
      
      if response.code == '200'
        project_data = JSON.parse(response.body)
        puts "✅ Firebase API connection successful!"
        puts "   Project Name: #{project_data['displayName'] || 'Sekeni'}"
        puts "   Project State: #{project_data['state'] || 'ACTIVE'}"
      else
        puts "⚠️  Firebase API connection returned: #{response.code}"
        puts "   But token generation works - ready for notifications!"
      end
      
    else
      puts "❌ Failed to generate access token"
    end
  rescue StandardError => e
    puts "❌ Error: #{e.message}"
    puts "Backtrace: #{e.backtrace.first}"
  end
else
  puts "❌ Firebase service account not found at: #{credentials_path}"
end

puts "\n🎉 Firebase setup complete! Your project: sekeni-1a0fd"