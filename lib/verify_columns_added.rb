
# lib/verify_columns_added.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Verifying Columns Were Added..."
puts "=" * 35

Order.reset_column_information

puts "Order columns:"
Order.column_names.each { |col| puts "  - #{col}" }

puts "\nChecking specific columns:"
puts "payment_proof: #{Order.column_names.include?('payment_proof') ? '✅' : '❌'}"
puts "proof_notes: #{Order.column_names.include?('proof_notes') ? '✅' : '❌'}"

# Test that we can use the columns
order = Order.create!(
  order_number: "VERIFY#{Time.current.strftime('%m%d%H%M%S')}",
  total_amount: 100.00,
  buyer_id: User.first.id,
  shop_id: Shop.first.id,
  status: 'pending'
)

order.update!(
  payment_proof: 'test_proof_data',
  proof_notes: 'test_notes_data'
)

puts "\nTest update successful!"
puts "Payment proof: #{order.payment_proof}"
puts "Proof notes: #{order.proof_notes}"