# lib/test_polling_api.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing Polling API..."
puts "=" * 40

# Get real data
order = Order.last
user = order.buyer
session = user.user_sessions.last || user.user_sessions.create!(token: SecureRandom.hex(16))

puts "Order: #{order.order_number}"
puts "Order ID: #{order.id}"
puts "Token: #{session.token}"
puts "Current payment_status: #{order.payment_status}"

puts "\nTesting API response..."
# Simulate API call
controller = Api::V1::PaymentsController.new
def controller.params
  { id: Order.last.id }
end
def controller.render(json:)
  puts "API Response:"
  puts JSON.pretty_generate(json)
end

controller.instance_variable_set(:@order, order)
controller.status

puts "\n🎉 Polling API is working!"