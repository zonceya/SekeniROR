# lib/test_amount_mismatch.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing Amount Mismatch..."
puts "=" * 40

# Create a test order with different amount
test_order = Order.create!(
  order_number: '67890',
  total_amount: 300.00,  # Different amount
  buyer_id: User.first.id,
  shop_id: Shop.first.id,
  status: 'pending'
)

# Test email with different amount
mismatch_email = {
  payload: {
    headers: [
      { name: 'From', value: 'notifications@absa.co.za' },
      { name: 'Date', value: Time.current.rfc2822 }
    ],
    body: { 
      data: Base64.strict_encode64(<<~EMAIL)
        Dear Customer,
        You have received a payment of R500.00 from JOHN DOE.  # Different amount
        Reference: ORDER-67890
        Date: #{Time.current.strftime('%Y-%m-%d')}
      EMAIL
    }
  }
}

parsed = Gmail::BankEmailParser.parse(mismatch_email)
puts "Parsed email:"
puts "Bank: #{parsed[:bank]}"
puts "Amount: R#{parsed[:amount]}"
puts "Reference: #{parsed[:reference]}"

order_number_from_ref = parsed[:reference].gsub(/[^0-9]/, '')
order = Order.find_by(order_number: order_number_from_ref)

if order && order.total_amount == parsed[:amount]
  puts "✅ SUCCESS: Matched order ##{order.order_number}"
else
  puts "❌ NO MATCH: Amount mismatch"
  puts "Order amount: R#{order.total_amount}"
  puts "Payment amount: R#{parsed[:amount]}"
end