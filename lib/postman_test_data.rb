# lib/postman_test_data.rb
puts "POSTMAN TEST DATA GENERATOR"
puts "==========================="

# Create test user if needed
user = User.find_by(email: "test@sekeni.com") || User.create!(
  email: "test@sekeni.com",
  password: "password123",
  name: "Test User"
)

# Create test notifications
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

puts "✅ Test user created:"
puts "   Email: test@sekeni.com"
puts "   Password: password123"
puts "   Notifications: #{user.notifications.count}"

puts "\n🎯 POSTMAN TEST ENDPOINTS:"
puts "   GET    /api/v1/notifications"
puts "   PUT    /api/v1/notifications/1/read"
puts "   GET    /api/v1/notifications/unread_count"
puts "   POST   /api/v1/users/firebase_token"
puts "\n🔑 Use this user's auth token for testing"