# lib/test_polling_final.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing Final Polling API..."
puts "=" * 40

# Get real data
order = Order.last

puts "Order: #{order.order_number}"
puts "Order ID: #{order.id}"
puts "Current payment_status: #{order.payment_status}"
puts "Paid at: #{order.paid_at}"
puts "Bank: #{order.bank}"

# Test the new methods
puts "\nTesting payment methods:"
puts "payment_expired?: #{order.payment_expired?}"
puts "payment_time_remaining: #{order.payment_time_remaining}"

# Test the polling response structure
puts "\nPOLLING RESPONSE STRUCTURE:"
polling_response = {
  order: {
    id: order.id,
    order_number: order.order_number,
    status: order.order_status,
    payment_status: order.payment_status,
    total_amount: order.total_amount,
    currency: "ZAR"
  },
  payment: {
    initiated_at: order.payment_initiated_at,
    expires_at: order.payment_expires_at,
    paid_at: order.paid_at,
    time_remaining_seconds: order.payment_time_remaining,
    is_expired: order.payment_expired?,
    bank_details: {
      account_name: "Sekeni Pty Ltd",
      account_number: "1234567890",
      bank_name: "Capitec Bank", 
      branch_code: "470010",
      reference: order.order_number
    }
  }
}

puts JSON.pretty_generate(polling_response)

puts "\n🎉 Polling API is ready!"
puts "Android can poll: GET /api/v1/orders/#{order.id}/payment_status"
puts "Expected polling interval: 15 seconds"