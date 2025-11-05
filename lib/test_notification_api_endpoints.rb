# lib/test_notification_api_endpoints.rb
puts "Testing Notification API Endpoints"
puts "=================================="

# Get the test user and token
user = User.find_by(email: "test@sekeni.com")

if user
  puts "✅ Test user: #{user.email}"
  puts "📊 User notifications: #{user.notifications.count}"
  
  # Create a session to get token
  session = user.user_sessions.last
  if session
    puts "🎯 AUTH TOKEN: #{session.token}"
    puts ""
    puts "📋 POSTMAN TEST COLLECTION:"
    puts "1. GET    http://localhost:3000/api/v1/notifications"
    puts "2. PUT    http://localhost:3000/api/v1/notifications/1/read"
    puts "3. GET    http://localhost:3000/api/v1/notifications/unread_count"
    puts "4. POST   http://localhost:3000/api/v1/users/firebase_token"
    puts ""
    puts "🔑 Use this Authorization header:"
    puts "   Authorization: Bearer #{session.token}"
  else
    puts "❌ No active session found for user"
    puts "   Run the sign_in endpoint first to get a token"
  end
  
else
  puts "❌ Test user not found"
end