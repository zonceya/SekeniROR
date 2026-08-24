# db/seeds_sizes_staging.rb
puts "📏 Seeding School Sizes for Staging..."
puts "=" * 60

# Standard school uniform sizes
sizes = [
  "XS", "S", "M", "L", "XL", "XXL", "XXXL",
  "One Size", "4XL", "5XL",
  
  # Numeric sizes
  "28", "30", "32", "34", "36", "38", "40", "42", "44",
  "46", "48", "50", "52", "54",
  
  # Waist sizes
  "26", "27", "28", "29", "30", "31", "32", "33", "34",
  "35", "36", "38", "40",
  
  # Shoe sizes (UK)
  "UK 1", "UK 2", "UK 3", "UK 4", "UK 5", 
  "UK 6", "UK 7", "UK 8", "UK 9", "UK 10",
  "UK 11", "UK 12",
  
  # Boot sizes
  "Boot 8", "Boot 9", "Boot 10", "Boot 11", "Boot 12",
  
  # Numeric sizes (Euro)
  "EU 36", "EU 37", "EU 38", "EU 39", "EU 40",
  "EU 41", "EU 42", "EU 43", "EU 44", "EU 45",
  
  # Kid sizes
  "Child XS", "Child S", "Child M", "Child L",
  "Child 2-3", "Child 4-5", "Child 6-7", "Child 8-9",
  "Child 10-11", "Child 12-13",
  
  # Girls specific
  "Girls 6", "Girls 7", "Girls 8", "Girls 9", 
  "Girls 10", "Girls 11", "Girls 12", "Girls 13",
  
  # Boys specific
  "Boys 6", "Boys 7", "Boys 8", "Boys 9",
  "Boys 10", "Boys 11", "Boys 12", "Boys 13"
]

puts "📦 Creating #{sizes.count} sizes..."

created = 0
existing = 0

sizes.each do |size_name|
  size = ItemSize.find_or_create_by(name: size_name)
  if size.persisted?
    created += 1
    puts "✅ Created: #{size_name}"
  else
    existing += 1
  end
end

puts ""
puts "=" * 60
puts "📊 Summary:"
puts "  ✅ Created: #{created}"
puts "  ℹ️  Existing: #{existing}"
puts "  📚 Total Sizes: #{ItemSize.count}"