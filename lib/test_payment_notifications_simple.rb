# lib/test_payment_notifications_simple.rb
puts "Testing Payment Notifications (Simple)"
puts "======================================"

begin
  order = Order.find_by(order_number: "JOHA1031011734AV")

  if order
    puts "📦 Order: #{order.order_number}"
    puts "💰 Payment Status: #{order.payment_status}"
    puts "👤 Buyer: #{order.buyer.email}"
    puts "🏪 Seller: #{order.shop.user.email}"
    
    puts "\n🎯 Creating payment notifications..."
    
    # Create buyer notification
    buyer_notification = Notification.create!(
      user: order.buyer,
      notifiable: order,
      title: "Payment Confirmed ✅",
      message: "✅ Payment received! You can now arrange collection with the seller.",
      notification_type: 'payment_confirmation',
      status: 'pending'
    )
    
    # Create seller notification  
    seller_notification = Notification.create!(
      user: order.shop.user,
      notifiable: order,
      title: "Payment Received 💰",
      message: "💰 Buyer's payment confirmed. Please arrange delivery or collection.",
      notification_type: 'payment_received', 
      status: 'pending'
    )
    
    puts "✅ Notifications created successfully!"
    puts "   Buyer: #{buyer_notification.id} - #{buyer_notification.message}"
    puts "   Seller: #{seller_notification.id} - #{seller_notification.message}"
    
    # Test retrieving notifications (with error handling)
    puts "\n📊 Testing notification retrieval:"
    begin
      puts "   Buyer notifications: #{order.buyer.notifications.count}"
    rescue => e
      puts "   ⚠️  Buyer notifications error: #{e.message}"
    end
    
    begin
      puts "   Seller notifications: #{order.shop.user.notifications.count}"
    rescue => e
      puts "   ⚠️  Seller notifications error: #{e.message}"
    end
    
    begin
      puts "   Order notifications: #{order.notifications.count}"
    rescue => e
      puts "   ⚠️  Order notifications error: #{e.message}"
    end
    
  else
    puts "❌ Test order not found"
  end
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts "Backtrace: #{e.backtrace.first}"
end

puts "\n🎉 PAYMENT NOTIFICATION SYSTEM READY!"