# lib/check_enum_values.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Checking Order payment_status enum..."
puts "=" * 40

# Check current enum values
puts "Current payment_status values:"
puts Order.payment_statuses.inspect

# Check the column type
column = Order.connection.columns('orders').find { |c| c.name == 'payment_status' }
puts "Column type: #{column.sql_type}"

# Test what values are accepted
test_values = ['unpaid', 'paid', 'refunded', 'awaiting_verification']

test_values.each do |value|
  begin
    order = Order.new(payment_status: value)
    puts "#{value}: #{order.valid? ? '✅' : '❌'} #{order.errors.full_messages}"
  rescue => e
    puts "#{value}: ❌ #{e.message}"
  end
end