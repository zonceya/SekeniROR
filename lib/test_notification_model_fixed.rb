# lib/test_notification_model_fixed.rb
puts "Testing Notification Model (Fixed)"
puts "=================================="

begin
  # Test if Notification class exists and can be instantiated
  puts "Notification class defined: #{defined?(Notification)}"
  
  # Test creating a notification without using enums initially
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
      
      # Test enum methods
      puts "   Can mark as read: #{notification.respond_to?(:mark_as_read)}"
    else
      puts "❌ Failed to create notification: #{notification.errors.full_messages}"
    end
  else
    puts "⚠️  Need at least one order and user to test"
    puts "   Available orders: #{Order.count}"
    puts "   Available users: #{User.count}"
  end
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(3).join('\n')}"
end