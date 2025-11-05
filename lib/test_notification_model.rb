# lib/test_notification_model.rb
puts "Testing Notification Model"
puts "=========================="

begin
  # Test if Notification class exists
  puts "Notification class defined: #{defined?(Notification)}"
  
  # Test creating a notification
  order = Order.first
  user = User.first
  
  if order && user
    notification = Notification.new(
      user: user,
      notifiable: order,
      title: "Test Notification",
      message: "Testing the notification model",
      notification_type: 'system_alert',
      status: 'pending',
      read: false
    )
    
    if notification.save
      puts "✅ Notification created successfully!"
      puts "   ID: #{notification.id}"
      puts "   Type: #{notification.notification_type}"
      puts "   Status: #{notification.status}"
    else
      puts "❌ Failed to create notification: #{notification.errors.full_messages}"
    end
  else
    puts "⚠️  Need at least one order and user to test"
  end
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts "Backtrace: #{e.backtrace.first}"
end