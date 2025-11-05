# lib/test_complete_payment_flow.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Complete Payment Flow Test..."
puts "=" * 40

# Clear previous test data
Order.where("order_number LIKE ?", "%TEST%").destroy_all
FlaggedPayment.destroy_all

# Create test order
order = Order.create!(
  order_number: "FLOW#{Time.current.strftime('%m%d%H%M%S')}#{SecureRandom.alphanumeric(2).upcase}",
  total_amount: 420.00,
  buyer_id: User.first.id,
  shop_id: Shop.first.id,
  status: 'pending'
)

puts "1. Order created: ##{order.order_number} (R#{order.total_amount})"

# Test successful payment
puts "\n2. Testing successful payment..."
successful_email = {
  bank: 'absa',
  amount: 420.00,
  reference: order.order_number,  # Exact match
  timestamp: Time.current
}

PaymentProcessorJob.new.perform(successful_email)
order.reload
puts "   Status: #{order.payment_status}"
puts "   Bank: #{order.bank}"

# Test amount mismatch
puts "\n3. Testing amount mismatch..."
mismatch_email = {
  bank: 'fnb',
  amount: 400.00,  # Different amount
  reference: order.order_number,
  timestamp: Time.current
}

PaymentProcessorJob.new.perform(mismatch_email)
puts "   Flagged payments: #{FlaggedPayment.count}"

# Test order not found
puts "\n4. Testing order not found..."
not_found_email = {
  bank: 'capitec',
  amount: 500.00,
  reference: 'NONEXISTENT123',  # Doesn't exist
  timestamp: Time.current
}

PaymentProcessorJob.new.perform(not_found_email)
puts "   Flagged payments: #{FlaggedPayment.count}"

puts "\n🎉 Complete flow test finished!"