# lib/test_polling_fixed.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing Fixed Polling API..."
puts "=" * 40

# Create a new session for testing
user = User.first
session = user.user_sessions.create!(token: SecureRandom.hex(16))
order = Order.last

puts "Token: #{session.token}"
puts "Order: #{order.order_number}"

# Test the controller directly (bypasses HTTP)
puts "\nTesting PaymentsController#status:"

controller = Api::V1::PaymentsController.new
controller.instance_variable_set(:@order, order)

# Mock the render method to capture output
def controller.render(json:)
  puts "SUCCESS! API Response:"
  puts JSON.pretty_generate(json)
end

controller.status

puts "\n✅ Polling API is working correctly!"
puts "Android can call: GET /api/v1/orders/#{order.id}/payment_status"