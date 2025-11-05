# lib/check_payment_status.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Checking Payment Status Values..."
puts "=" * 35

puts "Current payment_status values: #{Order.payment_statuses.inspect}"

# Check if awaiting_verification is already there
if Order.payment_statuses.include?('awaiting_verification')
  puts "✅ awaiting_verification is already in the enum!"
else
  puts "❌ awaiting_verification is not in the enum"
  puts "But that's okay - we'll use an existing status for now"
end

# Test all available statuses
puts "\nTesting available statuses:"
Order.payment_statuses.each do |status, value|
  begin
    order = Order.new(payment_status: status)
    puts "#{status} (#{value}): ✅ Works"
  rescue => e
    puts "#{status} (#{value}): ❌ #{e.message}"
  end
end