# lib/test_awaiting_verification.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing Awaiting Verification Status..."
puts "=" * 40

puts "Available statuses: #{Order.payment_statuses.inspect}"

# Test if we can use awaiting_verification
begin
  order = Order.create!(
    order_number: "AWAIT#{Time.current.strftime('%m%d%H%M%S')}",
    total_amount: 150.00,
    buyer_id: User.first.id,
    shop_id: Shop.first.id,
    status: 'pending',
    payment_status: 'awaiting_verification'
  )
  
  puts "✅ awaiting_verification status works!"
  puts "Order status: #{order.payment_status}"
  
rescue => e
  puts "❌ awaiting_verification failed: #{e.message}"
  puts "Trying with integer value..."
  
  # Try with integer value
  order = Order.create!(
    order_number: "AWAIT2#{Time.current.strftime('%m%d%H%M%S')}",
    total_amount: 150.00,
    buyer_id: User.first.id,
    shop_id: Shop.first.id,
    status: 'pending',
    payment_status: 4  # Integer value for awaiting_verification
  )
  
  puts "✅ Integer value 4 works! Status: #{order.payment_status}"
end