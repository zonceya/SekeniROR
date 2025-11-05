# lib/check_order_associations.rb
puts "Checking Order Associations"
puts "==========================="

order = Order.first

if order
  puts "📦 Order: #{order.order_number}"
  puts "💰 Payment Status: #{order.payment_status}"
  
  # Check buyer association
  if order.respond_to?(:buyer) && order.buyer
    puts "✅ Buyer: #{order.buyer.email} (ID: #{order.buyer.id})"
  else
    puts "❌ No buyer association or buyer not found"
  end
  
  # Check shop association
  if order.respond_to?(:shop) && order.shop
    puts "✅ Shop: #{order.shop.name} (ID: #{order.shop.id})"
    
    # Check shop user
    if order.shop.respond_to?(:user) && order.shop.user
      puts "✅ Shop User: #{order.shop.user.email}"
    else
      puts "❌ Shop has no user association"
    end
  else
    puts "❌ No shop association or shop not found"
  end
  
  # Check if we can create notifications
  if order.buyer
    notification = Notification.new(
      user: order.buyer,
      notifiable: order,
      title: "Test",
      message: "Test message",
      notification_type: 'system_alert',
      status: 'pending'
    )
    puts "✅ Can create notification: #{notification.valid?}"
  end
  
else
  puts "❌ No orders found"
end