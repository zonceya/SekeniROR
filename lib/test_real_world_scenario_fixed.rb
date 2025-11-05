# lib/test_real_world_scenario_fixed.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Real-World Scenario Test (Fixed)..."
puts "=" * 45

# Create order with real format
shop = Shop.first || Shop.create!(name: "FashionHub", user: User.first)
order = Order.create!(
  order_number: "JOHA#{Time.current.strftime('%m%d%H%M%S')}#{SecureRandom.alphanumeric(2).upcase}",
  total_amount: 350.00,
  buyer_id: User.first.id,
  shop: shop,
  status: 'pending'
)

puts "🛒 Order created: #{order.order_number} (R#{order.total_amount})"

# Simulate bank emails using the ACTUAL order number
bank_emails = [
  {
    bank: 'absa',
    body: "Payment of R350.00 received. Reference: #{order.order_number}. Thank you."
  },
  {
    bank: 'fnb', 
    body: "Credit Alert: R350.00. Reference: ORDER-#{order.order_number}. Balance: R5000.00"
  },
  {
    bank: 'capitec',
    body: "Amount: R350.00. Ref: #{order.order_number}. Time: 12:30"
  }
]

bank_emails.each do |email|
  puts "\n📧 Processing #{email[:bank].upcase} email:"
  puts "Email body: #{email[:body]}"
  
  # Extract reference
  reference = case email[:bank]
  when 'absa'
    email[:body].match(/Reference:[\s]*(\S+)/i)&.captures&.first
  when 'fnb'
    email[:body].match(/Reference:[\s]*(\S+)/i)&.captures&.first
  when 'capitec'
    email[:body].match(/Ref:[\s]*(\S+)/i)&.captures&.first
  end
  
  puts "Extracted reference: #{reference}"
  
  # Find matching order
  matched_order = Order.find_by(order_number: reference)
  if matched_order
    puts "✅ Direct match found: #{matched_order.order_number}"
  else
    # Try enhanced extraction
    extracted = reference.to_s
      .gsub(/^(ORDER|REF|PAYMENT|REFERENCE)[\s\-:]*/i, '')
      .gsub(/[\s\-].*$/, '')
      .gsub(/\.$/, '')  # Remove trailing dot
    
    matched_order = Order.find_by(order_number: extracted)
    puts "Enhanced match: #{matched_order ? '✅' : '❌'} -> '#{extracted}'"
  end
  
  if matched_order && matched_order.total_amount == 350.00
    puts "💰 Payment confirmed! Order ##{matched_order.order_number}"
    
    # Process the payment
    matched_order.update!(
      payment_status: :paid,
      paid_at: Time.current,
      bank: email[:bank]
    )
    puts "✅ Order marked as paid!"
    
  elsif matched_order
    puts "⚠️ Amount mismatch: Order R#{matched_order.total_amount} vs Payment R350.00"
  else
    puts "❌ No order found for reference"
  end
end