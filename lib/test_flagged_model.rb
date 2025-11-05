# lib/test_flagged_model.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing FlaggedPayment Model..."
puts "=" * 40

# Test creating a simple flagged payment without order
begin
  flagged = FlaggedPayment.new(
    reference: 'TEST-123',
    received_amount: 500.00,
    bank: 'absa',
    status: 'order_not_found'
  )
  
  if flagged.save
    puts "✅ Successfully created flagged payment: #{flagged.id}"
  else
    puts "❌ Validation errors: #{flagged.errors.full_messages}"
  end
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(5)
end