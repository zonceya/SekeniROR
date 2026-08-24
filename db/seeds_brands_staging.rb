# db/seeds_brands_staging.rb
puts "🏷️ Seeding Brands for Staging..."
puts "=" * 60

# All brands needed for staging
brands = [
  # Sports Brands
  "Nike", "Adidas", "Puma", "Speedo", "Arena",
  "Asics", "New Balance", "Reebok", "Umbro", 
  "Under Armour", "Kappa", "Mizuno",
  "Canterbury", "Gilbert", "Gray-Nicolls", 
  "Kookaburra", "Slazenger", "Wilson", 
  "Head", "Prince", "Dunlop",
  "Buccaneers", "Rage", "Street Fever",
  
  # Stationery Brands
  "BIC", "Pritt", "Oxford", "Casio", 
  "Staedtler", "Stabilo", "Faber-Castell", 
  "Pilot", "Pentel", "Maped", "Sharp",
  "Aadil", "Typek", "Bic", "Croxley", 
  "King", "Maped",
  
  # School Uniform Brands
  "Student Prince", "Toughees", "Buggies",
  "School Uniform Centre", "School Uniform Direct",
  "School Wear SA", "Schoolwear Centre", 
  "The School Shop", "Uniform City", 
  "Uniform Warehouse", "PEP Student Price",
  
  # Retail Brands
  "PEP", "PEP School Shoes", "Ackermans", 
  "Ackermans School Shoes", "Mr Price", 
  "Mr Price Sport", "Woolworths", 
  "Woolworths School Shoes", "Edgars", 
  "Exact", "Jet", "Checkers", "Pick n Pay",
  "Clicks", "Dis-Chem", "Game", "Makro",
  
  # School Specific Brands
  "Barron", "Bata", "Bubblegummers", 
  "Grasshoppers", "Hush Puppies", "S.A. School Shoes"
]

puts "📦 Creating #{brands.count} brands..."

created = 0
existing = 0

brands.each do |brand_name|
  brand = Brand.find_or_create_by(name: brand_name)
  if brand.persisted?
    created += 1
    puts "✅ Created: #{brand_name}"
  else
    existing += 1
  end
end

puts ""
puts "=" * 60
puts "📊 Summary:"
puts "  ✅ Created: #{created}"
puts "  ℹ️  Existing: #{existing}"
puts "  📚 Total Brands: #{Brand.count}"