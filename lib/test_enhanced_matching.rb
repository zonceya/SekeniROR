# lib/test_enhanced_matching.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing Enhanced Order Matching..."
puts "=" * 45

# Create test order
shop = Shop.first || Shop.create!(name: "TestShop", user: User.first)
order = Order.create!(
  order_number: "SHOP0123456789AB",  # Example format
  total_amount: 250.00,
  buyer_id: User.first.id,
  shop: shop,
  status: 'pending'
)

puts "Order number: #{order.order_number}"

# Test various bank reference formats
test_cases = [
  { reference: "SHOP0123456789AB", description: "Exact match" },
  { reference: "ORDER-SHOP0123456789AB", description: "With ORDER- prefix" },
  { reference: "REF:SHOP0123456789AB", description: "With REF: prefix" },
  { reference: "PAYMENT SHOP0123456789AB", description: "With PAYMENT prefix" },
  { reference: "SHOP0123456789AB Payment received", description: "With suffix" },
  { reference: "Invalid123", description: "Invalid reference" }
]

test_cases.each do |test|
  puts "\nTesting: #{test[:description]}"
  puts "Reference: '#{test[:reference]}'"
  
  # Test extraction
  extracted = test[:reference].to_s
    .gsub(/^(ORDER|REF|PAYMENT|REFERENCE)[\s\-:]*/i, '')
    .gsub(/[\s\-].*$/, '')
  
  puts "Extracted: '#{extracted}'"
  
  # Test matching
  matched_order = Order.find_by(order_number: extracted)
  puts "Match: #{matched_order ? '✅' : '❌'}"
  puts "Matched order: #{matched_order&.order_number}" if matched_order
end