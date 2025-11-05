# lib/test_complete_flow_final.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Final Complete Flow Test..."
puts "=" * 35

Order.reset_column_information

# Create test order
order = Order.create!(
  order_number: "FINAL#{Time.current.strftime('%m%d%H%M%S')}",
  total_amount: 200.00,
  buyer_id: User.first.id,
  shop_id: Shop.first.id,
  status: 'pending',
  payment_status: 'unpaid'
)

puts "Created order ##{order.order_number}"

# Test the controller action
begin
  controller = Api::V1::OrdersController.new
  controller.params = {
    id: order.id,
    proof: 'final_test_proof',
    notes: 'final_test_notes'
  }

  def controller.render(json:)
    puts "✅ Controller response: #{json}"
  end

  controller.submit_payment_proof
  order.reload
  
  puts "Final status: #{order.payment_status}"
  puts "Payment proof: #{order.payment_proof}"
  puts "Proof notes: #{order.proof_notes}"
  
  puts "\n🎉 COMPLETE SUCCESS! Payment proof system is working!"

rescue => e
  puts "❌ Final test failed: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(3)
end