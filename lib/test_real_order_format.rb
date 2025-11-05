# lib/test_real_order_format.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing Real Order Number Format..."
puts "=" * 45

# Create a test shop first
shop = Shop.first || Shop.create!(name: "TestShop", user: User.first)

# Create order with real format
order = Order.new(
  total_amount: 250.00,
  buyer_id: User.first.id,
  shop: shop,
  status: 'pending'
)

# Manually assign order number to see the format
shop_code = shop.name[0..3].upcase
time_code = Time.current.strftime("%m%d%H%M%S")
random_suffix = SecureRandom.alphanumeric(2).upcase
order.order_number = "#{shop_code}#{time_code}#{random_suffix}"

order.save!
puts "Created order: #{order.order_number}"
puts "Format: ShopCode(#{shop_code}) + Time(#{time_code}) + Random(#{random_suffix})"

# Test payment matching
test_references = [
  order.order_number,  # Exact match
  "ORDER-#{order.order_number}",  # Common bank format
  "REF-#{order.order_number}",    # Alternative format
  "Payment for #{order.order_number}"  # Descriptive
]

test_references.each do |ref|
  matched_order = Order.find_by(order_number: ref)
  puts "Reference: '#{ref}' -> Match: #{matched_order ? '✅' : '❌'}"
end