# lib/generate_auth_token.rb
puts "Generating Auth Token for Test User"
puts "==================================="

user = User.find_by(email: "test@sekeni.com")

if user
  puts "✅ User found: #{user.email}"
  
  # Create a new session (simulate sign in)
  user.user_sessions.destroy_all # Clear existing sessions
  session = user.user_sessions.create!(token: SecureRandom.hex(32))
  
  puts "🎯 AUTH TOKEN GENERATED:"
  puts "   #{session.token}"
  puts ""
  puts "📋 Use this token in Postman:"
  puts "   Authorization: Bearer #{session.token}"
  puts ""
  puts "🔗 POSTMAN COLLECTION:"
  puts "   GET    /api/v1/notifications"
  puts "   PUT    /api/v1/notifications/1/read" 
  puts "   GET    /api/v1/notifications/unread_count"
  puts "   POST   /api/v1/users/firebase_token"
  
else
  puts "❌ Test user not found"
end