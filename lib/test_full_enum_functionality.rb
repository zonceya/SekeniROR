# lib/test_full_enum_functionality.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing full enum functionality..."
puts "=" * 45

begin
  puts "1. Testing enum values..."
  puts "Available statuses: #{FlaggedPayment.statuses.inspect}"
  
  puts "2. Testing scopes..."
  puts "Amount mismatch scope: #{FlaggedPayment.amount_mismatch.to_sql}"
  puts "Order not found scope: #{FlaggedPayment.order_not_found.to_sql}"
  
  puts "3. Testing instance methods..."
  flagged = FlaggedPayment.new(status: 'order_not_found')
  puts "order_not_found? : #{flagged.order_not_found?}"
  puts "amount_mismatch? : #{flagged.amount_mismatch?}"
  puts "manual_review? : #{flagged.manual_review?}"
  
  puts "4. Testing bang methods..."
  flagged.save!
  flagged.amount_mismatch!
  puts "After amount_mismatch!: #{flagged.status}"
  
  puts "✅ All enum functionality works!"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(3)
end