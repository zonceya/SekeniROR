# lib/fix_notification_test_data.rb
puts "Fixing Notification Test Data"
puts "============================="

# Get the user you're actually signed in as
user = User.find_by(email: "TestOrders@example.com")

if user
  puts "✅ Found signed-in user: #{user.email} (ID: #{user.id})"
  
  # Clear existing notifications
  user.notifications.destroy_all
  
  # Create new test notifications
  order = Order.first
  if order
    3.times do |i|
      Notification.create!(
        user: user,
        notifiable: order,
        title: "Test Notification #{i+1}",
        message: "This is test notification #{i+1} for Postman testing",
        notification_type: 'system_alert',
        status: 'pending',
        read: false
      )
    end
  end
  
  puts "✅ Created 3 test notifications for #{user.email}"
  puts "📊 Total notifications: #{user.notifications.count}"
  
  # Show the notifications (with error handling)
  puts "\n📋 User Notifications:"
  if user.notifications.any?
    user.notifications.each do |notification|
      puts "   ID: #{notification.id} | #{notification.title}"
      puts "      #{notification.message}"
      puts "      Read: #{notification.read} | Type: #{notification.notification_type}"
      puts ""
    end
  else
    puts "   No notifications found"
  end
  
  # Get the session token
  session = user.user_sessions.last
  if session
    puts "🎯 AUTH TOKEN: #{session.token}"
    puts ""
    puts "📝 POSTMAN TEST COMMANDS:"
    puts "   GET    /api/v1/notifications"
    
    if user.notifications.any?
      puts "   PUT    /api/v1/notifications/#{user.notifications.first.id}/read"
    else
      puts "   PUT    /api/v1/notifications/1/read (create notifications first)"
    end
    
    puts "   GET    /api/v1/notifications/unread_count"
  end
  
else
  puts "❌ User not found"
end