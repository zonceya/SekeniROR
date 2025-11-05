# lib/test_payment_processor_simple.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing Payment Processor Job (Simple)..."
puts "=" * 55

# Create test order
order = Order.create!(
  order_number: '12345',
  total_amount: 500.00,
  buyer_id: User.first.id,
  shop_id: Shop.first.id,
  status: 'pending'
)

puts "Created test order: ##{order.order_number} for R#{order.total_amount}"

# Test successful payment
success_email = {
  payload: {
    headers: [{ name: 'From', value: 'notifications@absa.co.za' }],
    body: { data: Base64.strict_encode64("Payment of R500.00 Reference: ORDER-12345") }
  }
}

puts "\nTesting successful payment:"
parsed = Gmail::BankEmailParser.parse(success_email)
puts "Parsed: Bank: #{parsed[:bank]}, Amount: R#{parsed[:amount]}, Reference: #{parsed[:reference]}"

PaymentProcessorJob.new.perform(parsed)

# Check result
order.reload
puts "Order status: #{order.payment_status}"
puts "Paid at: #{order.paid_at}"
puts "Bank: #{order.bank}"

# Test amount mismatch
order2 = Order.create!(
  order_number: '67890',
  total_amount: 300.00,
  buyer_id: User.first.id,
  shop_id: Shop.first.id,
  status: 'pending'
)

mismatch_email = {
  payload: {
    headers: [{ name: 'From', value: 'notifications@fnb.co.za' }],
    body: { data: Base64.strict_encode64("Credit: R500.00 Reference: ORDER-67890") }
  }
}

puts "\nTesting amount mismatch:"
parsed2 = Gmail::BankEmailParser.parse(mismatch_email)
puts "Parsed: Bank: #{parsed2[:bank]}, Amount: R#{parsed2[:amount]}, Reference: #{parsed2[:reference]}"

PaymentProcessorJob.new.perform(parsed2)
order2.reload
puts "Order status: #{order2.payment_status} (should still be pending)"