# lib/test_uuid_setup.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing UUID Setup..."
puts "=" * 40

# Check if flagged_payments table exists with correct type
if ActiveRecord::Base.connection.table_exists?('flagged_payments')
  puts "✅ flagged_payments table exists"
  
  # Check column types
  columns = ActiveRecord::Base.connection.columns('flagged_payments')
  id_column = columns.find { |c| c.name == 'id' }
  order_id_column = columns.find { |c| c.name == 'order_id' }
  
  puts "ID column type: #{id_column.sql_type}"
  puts "Order ID column type: #{order_id_column.sql_type}"
  
  # Test creating a flagged payment
  begin
    flagged = FlaggedPayment.create!(
      reference: 'TEST-123',
      received_amount: 500.00,
      bank: 'absa',
      status: 'order_not_found'
    )
    puts "✅ Successfully created flagged payment with UUID: #{flagged.id}"
  rescue => e
    puts "❌ Error creating flagged payment: #{e.message}"
  end
else
  puts "❌ flagged_payments table does not exist"
end