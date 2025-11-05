# lib/check_shop_model.rb
puts "Checking Shop Model Structure"
puts "============================="

shop = Shop.first

if shop
  puts "🏪 Shop: #{shop.name}"
  puts "Available methods:"
  shop.methods.grep(/user/).each { |m| puts "  - #{m}" }
  
  # Check common association names
  %w[user owner merchant seller].each do |assoc|
    if shop.respond_to?(assoc) && shop.send(assoc)
      puts "✅ Found #{assoc} association: #{shop.send(assoc).email}"
    end
  end
else
  puts "❌ No shops found"
end