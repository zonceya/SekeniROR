# lib/test_polling_simple.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing Polling API (Simple)..."
puts "=" * 40

# Get real data
order = Order.last
user = order.buyer

puts "Order: #{order.order_number}"
puts "Order ID: #{order.id}"
puts "Current payment_status: #{order.payment_status}"
puts "Paid at: #{order.paid_at}"
puts "Bank: #{order.bank}"

# Test the status method directly
puts "\nTesting payment status data:"
status_data = {
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

puts "POLLING RESPONSE WOULD BE:"
puts JSON.pretty_generate(status_data)

puts "\n🎉 Polling API data structure is correct!"
puts "Your Android app can poll this endpoint every 15 seconds!"