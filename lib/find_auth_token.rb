# lib/find_auth_token.rb
puts "Finding Auth Token for Test User"
puts "================================"

user = User.find_by(email: "test@sekeni.com")

if user
  puts "✅ User found: #{user.email}"
  
  # Check for existing sessions
  sessions = user.user_sessions
  if sessions.any?
    puts "✅ Existing sessions found:"
    sessions.each do |session|
      puts "   Token: #{session.token}"
      puts "   Created: #{session.created_at}"
    end
  else
    puts "❌ No existing sessions found"
    puts "   You need to sign in first to get an auth token"
  end
  
else
  puts "❌ Test user not found"
end