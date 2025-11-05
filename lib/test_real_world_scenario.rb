# lib/test_real_world_scenario.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Real-World Scenario Test..."
puts "=" * 35

# Create order with real format
shop = Shop.first || Shop.create!(name: "FashionHub", user: User.first)
order = Order.create!(
  order_number: "FASH0123456789XY",  # Example: FASH + timestamp + random
  total_amount: 350.00,
  buyer_id: User.first.id,
  shop: shop,
  status: 'pending'
)

puts "🛒 Order created: #{order.order_number} (R#{order.total_amount})"

# Simulate bank emails with different formats
bank_emails = [
  {
    bank: 'absa',
    body: "Payment of R350.00 received. Reference: FASH0123456789XY. Thank you."
  },
  {
    bank: 'fnb', 
    body: "Credit Alert: R350.00. Reference: ORDER-FASH0123456789XY. Balance: R5000.00"
  },
  {
    bank: 'capitec',
    body: "Amount: R350.00. Ref: FASH0123456789XY. Time: 12:30"
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
  order = Order.find_by(order_number: reference)
  if order
    puts "✅ Direct match found: #{order.order_number}"
  else
    # Try enhanced extraction
    extracted = reference.to_s
      .gsub(/^(ORDER|REF|PAYMENT|REFERENCE)[\s\-:]*/i, '')
      .gsub(/[\s\-].*$/, '')
    
    order = Order.find_by(order_number: extracted)
    puts "Enhanced match: #{order ? '✅' : '❌'} -> '#{extracted}'"
  end
  
  if order && order.total_amount == 350.00
    puts "💰 Payment confirmed! Order ##{order.order_number}"
  elsif order
    puts "⚠️ Amount mismatch: Order R#{order.total_amount} vs Payment R350.00"
  else
    puts "❌ No order found for reference"
  end
end