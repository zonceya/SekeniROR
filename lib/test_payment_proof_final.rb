# lib/test_payment_proof_final.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing Payment Proof Submission (Final)..."
puts "=" * 50

# Create test order
order = Order.create!(
  order_number: "FINAL#{Time.current.strftime('%m%d%H%M%S')}",
  total_amount: 250.00,
  buyer_id: User.first.id,
  shop_id: Shop.first.id,
  status: 'pending',
  payment_status: 'unpaid'
)

puts "Created test order: ##{order.order_number}"
puts "Initial payment status: #{order.payment_status}"

# Test the controller action
begin
  controller = Api::V1::OrdersController.new
  controller.params = {
    id: order.id,
    proof: 'test_proof_data',
    notes: 'Test payment proof'
  }

  def controller.render(json:)
    @response = json
  end

  controller.submit_payment_proof
  order.reload

  puts "Response: #{controller.instance_variable_get('@response')}"
  puts "Updated payment status: #{order.payment_status}"
  puts "Proof notes: #{order.proof_notes}"
  puts "Payment proof: #{order.payment_proof}"
  puts "✅ Controller test passed!"

rescue => e
  puts "❌ Controller test failed: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(3)
end