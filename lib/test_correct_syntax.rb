# lib/test_correct_syntax.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing corrected enum syntax..."
puts "=" * 40

begin
  # Test the model loads
  puts "Loading FlaggedPayment..."
  FlaggedPayment
  puts "✅ Model loads successfully"
  
  # Test creating instance
  puts "Creating instance..."
  flagged = FlaggedPayment.new(
    reference: 'TEST-CORRECTED',
    received_amount: 500.00,
    bank: 'absa',
    status: 'order_not_found'
  )
  
  if flagged.save
    puts "✅ Instance created successfully"
    puts "Status: #{flagged.status}"
    puts "Is order_not_found? #{flagged.order_not_found?}"
  else
    puts "❌ Validation errors: #{flagged.errors.full_messages}"
  end

rescue => e
  puts "❌ Error: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(3)
end