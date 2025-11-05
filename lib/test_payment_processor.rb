# lib/test_payment_processor.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing Payment Processor Job..."
puts "=" * 50

# Create test orders
Order.create!(
  order_number: '12345',
  total_amount: 500.00,
  buyer_id: User.first.id,
  shop_id: Shop.first.id,
  status: 'pending'
)

Order.create!(
  order_number: '67890', 
  total_amount: 300.00,
  buyer_id: User.first.id,
  shop_id: Shop.first.id,
  status: 'pending'
)

test_cases = [
  {
    name: "Successful payment",
    email: {
      payload: {
        headers: [{ name: 'From', value: 'notifications@absa.co.za' }],
        body: { data: Base64.strict_encode64("Payment of R500.00 Reference: ORDER-12345") }
      }
    }
  },
  {
    name: "Amount mismatch", 
    email: {
      payload: {
        headers: [{ name: 'From', value: 'notifications@fnb.co.za' }],
        body: { data: Base64.strict_encode64("Credit: R500.00 Reference: ORDER-67890") }
      }
    }
  },
  {
    name: "Order not found",
    email: {
      payload: {
        headers: [{ name: 'From', value: 'notifications@capitecbank.co.za' }],
        body: { data: Base64.strict_encode64("Amount: R1000.00 Ref: ORDER-99999") }
      }
    }
  }
]

test_cases.each do |test_case|
  puts "\n#{test_case[:name]}:"
  parsed = Gmail::BankEmailParser.parse(test_case[:email])
  PaymentProcessorJob.new.perform(parsed)
end

puts "\nFinal order statuses:"
Order.all.each do |order|
  puts "Order ##{order.order_number}: #{order.payment_status} (R#{order.total_amount})"
end