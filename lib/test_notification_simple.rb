# lib/test_notification_simple.rb
puts "Testing Notification Model (Simple)"
puts "==================================="

begin
  puts "Notification class defined: #{defined?(Notification)}"
  
  # Find test data
  order = Order.first
  user = User.first
  
  if order && user
    puts "✅ Found order: #{order.order_number}"
    puts "✅ Found user: #{user.email}"
    
    # Test 1: Create notification
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
      puts "   Notifiable Type: #{notification.notifiable_type}"
      puts "   Notifiable ID: #{notification.notifiable_id}"
      
      # Test 2: Test enum methods
      puts "\n🔧 Testing enum methods:"
      puts "   Can mark as read: #{notification.respond_to?(:mark_as_read)}"
      puts "   Status methods: #{notification.respond_to?(:pending?)}, #{notification.respond_to?(:delivered?)}"
      
      # Test 3: Mark as read
      notification.mark_as_read
      puts "   Read status after mark_as_read: #{notification.reload.read}"
      
      # Test 4: Update status
      notification.delivered!
      puts "   Status after delivered!: #{notification.reload.status}"
      
    else
      puts "❌ Failed to create notification: #{notification.errors.full_messages}"
    end
  else
    puts "⚠️  Need at least one order and user to test"
    puts "   Available orders: #{Order.count}"
    puts "   Available users: #{User.count}"
    
    # Show available users and orders
    User.all.each { |u| puts "   User: #{u.id} - #{u.email}" }
    Order.all.each { |o| puts "   Order: #{o.id} - #{o.order_number}" }
  end
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(3).join('\n')}"
end