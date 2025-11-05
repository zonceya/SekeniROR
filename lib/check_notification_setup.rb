# lib/check_notification_setup.rb
puts "Notification System Status Check"
puts "================================"

# Check models
puts "✅ Notification model: #{defined?(Notification)}"
puts "✅ Order model: #{defined?(Order)}"
puts "✅ User model: #{defined?(User)}"

# Check associations
begin
  user = User.first
  order = Order.first
  
  if user && order
    puts "✅ Can create notification: #{Notification.new(user: user, notifiable: order).valid?}"
    
    # Test enum values
    notification = Notification.new(
      user: user,
      notifiable: order,
      title: "Test",
      message: "Test",
      notification_type: 'payment_confirmation',
      status: 'pending'
    )
    puts "✅ Enum values work: #{notification.valid?}"
  end
rescue => e
  puts "❌ Setup issue: #{e.message}"
end

puts "\n🎉 Next: Add FirebaseDeliveryJob back when ready"