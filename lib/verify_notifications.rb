# lib/verify_notifications.rb
puts "Verifying Notifications"
puts "======================="

user = User.find_by(email: "TestOrders@example.com")

if user
  puts "✅ User: #{user.email} (ID: #{user.id})"
  puts "📊 Notifications count: #{user.notifications.count}"
  
  if user.notifications.any?
    puts "\n📋 All Notifications:"
    user.notifications.each do |notification|
      puts "   ID: #{notification.id} - #{notification.title}"
      puts "      Message: #{notification.message}"
      puts "      Read: #{notification.read} | Status: #{notification.status}"
      puts ""
    end
    
    puts "🎯 Test these endpoints:"
    puts "   GET    /api/v1/notifications"
    puts "   PUT    /api/v1/notifications/#{user.notifications.first.id}/read"
    puts "   GET    /api/v1/notifications/unread_count"
  else
    puts "❌ No notifications found for this user"
  end
  
else
  puts "❌ User not found"
end