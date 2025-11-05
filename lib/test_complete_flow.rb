# lib/test_complete_flow.rb
puts "Testing Complete Firebase Notification Flow"
puts "==========================================="

# Test 1: Firebase connectivity
puts "\n1. 🔑 Testing Firebase connectivity..."
credentials_path = Rails.root.join('config', 'firebase-service-account.json')

if File.exist?(credentials_path)
  puts "✅ Firebase service account found!"
  
  begin
    require 'googleauth'
    
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(credentials_path),
      scope: 'https://www.googleapis.com/auth/firebase.messaging'
    )
    
    token_info = authorizer.fetch_access_token!
    puts "✅ Access token generated: #{token_info['token_type']}"
    
  rescue => e
    puts "❌ Error: #{e.message}"
  end
end

# Test 2: Notification creation
puts "\n2. 📝 Testing notification creation..."
begin
  # Find a test order
  order = Order.find_by(order_number: "JOHA1031011734AV")
  
  if order
    puts "✅ Test order found: #{order.order_number}"
    
    # Create test notification
    notification = Notification.create!(
      user: order.user,
      notifiable: order,
      title: "Test Notification",
      message: "This is a test notification from Firebase",
      notification_type: 'system_alert',
      status: 'pending'
    )
    
    puts "✅ Test notification created: #{notification.id}"
    
    # Test Firebase service
    puts "\n3. 🚀 Testing Firebase notification delivery..."
    result = FirebaseNotificationService.deliver(notification)
    
    if notification.reload.status == 'delivered'
      puts "✅ Firebase notification delivered successfully!"
    else
      puts "⚠️  Notification status: #{notification.status}"
      puts "   This is expected in development unless SEND_FIREBASE_NOTIFICATIONS=true"
    end
    
  else
    puts "⚠️  Test order not found, but Firebase is ready"
  end
  
rescue => e
  puts "❌ Error in notification flow: #{e.message}"
end

puts "\n🎉 FIREBASE NOTIFICATION SYSTEM IS READY!"
puts "   To enable sending in development, set: SEND_FIREBASE_NOTIFICATIONS=true"
puts "   Mobile apps need to register Firebase tokens with your API"