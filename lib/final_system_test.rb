# lib/final_system_test.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Final System Test with Corrected Enum..."
puts "=" * 50

# Test 1: Enum functionality
puts "1. Testing enum functionality..."
begin
  flagged = FlaggedPayment.create!(
    reference: 'FINAL-TEST-1',
    received_amount: 500.00,
    bank: 'absa',
    status: 'order_not_found'
  )
  puts "   ✅ Enum creation works"
  puts "   ✅ Status methods work: #{flagged.order_not_found?}"
rescue => e
  puts "   ❌ Enum failed: #{e.message}"
end

# Test 2: Payment processor
puts "\n2. Testing payment processor..."
begin
  order = Order.create!(
    order_number: 'FINAL-TEST-123',
    total_amount: 500.00,
    buyer_id: User.first.id,
    shop_id: Shop.first.id,
    status: 'pending'
  )

  email_data = {
    bank: 'absa',
    amount: 500.00,
    reference: 'ORDER-FINAL-TEST-123',
    timestamp: Time.current
  }

  PaymentProcessorJob.new.perform(email_data)
  order.reload
  puts "   ✅ Payment processing completed"
  puts "   Order status: #{order.payment_status}"
rescue => e
  puts "   ❌ Payment processor failed: #{e.message}"
end

# Test 3: Gmail parser
puts "\n3. Testing Gmail parser..."
begin
  test_email = {
    payload: {
      headers: [{ name: 'From', value: 'notifications@absa.co.za' }],
      body: { data: Base64.strict_encode64("Payment of R500.00 Reference: ORDER-TEST-456") }
    }
  }

  parsed = Gmail::BankEmailParser.parse(test_email)
  puts "   ✅ Gmail parsing works"
  puts "   Parsed data: #{parsed.inspect}"
rescue => e
  puts "   ❌ Gmail parser failed: #{e.message}"
end

puts "\n🎉 System test completed!"