# db/seeds.rb
puts "Starting database seeding..."

# Clear existing data safely
ActiveRecord::Base.connection.disable_referential_integrity do
  tables = ActiveRecord::Base.connection.tables - ['schema_migrations', 'ar_internal_metadata']
  tables.each do |table|
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table} RESTART IDENTITY CASCADE")
  end
end

puts "1. Creating provinces..."
provinces = Province.create!([
  {name: "Eastern Cape"}, {name: "Free State"}, {name: "Gauteng"},
  {name: "KwaZulu-Natal"}, {name: "Limpopo"}, {name: "Mpumalanga"},
  {name: "North West"}, {name: "Northern Cape"}, {name: "Western Cape"}
])

puts "2. Creating towns..."
towns = Town.create!([
  {name: "Johannesburg", province_id: provinces[2].id},
  {name: "Pretoria", province_id: provinces[2].id},
  {name: "Cape Town", province_id: provinces[8].id},
  {name: "Durban", province_id: provinces[3].id},
  {name: "Bloemfontein", province_id: provinces[1].id}
])

puts "3. Creating locations..."
locations = Location.create!([
  {province: "Gauteng", town_id: towns[0].id},
  {province: "Gauteng", town_id: towns[1].id},
  {province: "Western Cape", town_id: towns[2].id},
  {province: "KwaZulu-Natal", town_id: towns[3].id},
  {province: "Free State", town_id: towns[4].id}
])

puts "4. Creating users..."
users = User.create!([
  {name: "System Admin", email: "admin@schoolsystem.com", password_digest: BCrypt::Password.create("Admin@123"), role: "admin", status: true},
  {name: "Shop Owner", email: "shopowner@example.com", password_digest: BCrypt::Password.create("Shop@123"), role: "user", status: true},
  {name: "Buyer User", email: "buyer@example.com", password_digest: BCrypt::Password.create("Buyer@123"), role: "user", status: true}
])

puts "5. Creating profiles..."
users.each do |user|
  Profile.create!(
    user: user,
    mobile: "+27#{rand(10**9).to_s.rjust(9, '0')}"
  )
end

puts "6. Creating shops..."
shops = Shop.create!([
  {user: users[1], name: "Johannesburg School Store", description: "Official store for Johannesburg schools", location: "Gauteng"},
  {user: users[0], name: "Test Shop", description: "Test shop for development", location: "Western Cape"}
])

puts "7. Creating brands..."
brands = Brand.create!([
  {name: "Nike"}, {name: "Adidas"}, {name: "Puma"}, 
  {name: "Cotton King"}, {name: "SchoolBrand"}
])

puts "8. Creating item conditions..."
item_conditions = ItemCondition.create!([
  {name: "New", description: "Brand new item"},
  {name: "Used - Like New", description: "Gently used, looks new"},
  {name: "Used - Good", description: "Used but in good condition"},
  {name: "Used - Fair", description: "Shows signs of wear"}
])

puts "9. Creating item sizes..."
item_sizes = ItemSize.create!([
  {name: "XS"}, {name: "S"}, {name: "M"}, {name: "L"}, {name: "XL"}
])

puts "10. Creating item colors..."
item_colors = ItemColor.create!([
  {name: "White"}, {name: "Black"}, {name: "Red"}, 
  {name: "Blue"}, {name: "Green"}, {name: "Grey"}
])

puts "11. Creating genders..."
genders = Gender.create!([
  {name: "Boys", category: "standard", display_name: "Boys", gender_group: "male"},
  {name: "Girls", category: "standard", display_name: "Girls", gender_group: "female"},
  {name: "Unisex", category: "standard", display_name: "Unisex", gender_group: "unisex"}
])

puts "12. Creating schools..."
schools = School.create!([
  {name: "Johannesburg High School", location_id: locations[0].id, school_type: "high", province_id: provinces[2].id},
  {name: "Pretoria Boys High", location_id: locations[1].id, school_type: "high", province_id: provinces[2].id},
  {name: "Cape Town Academy", location_id: locations[2].id, school_type: "primary", province_id: provinces[8].id}
])

puts "13. Creating tags..."
tags = Tag.create!([
  {name: "soccer", tag_type: "sport"},
  {name: "basketball", tag_type: "sport"},
  {name: "school team", tag_type: "team"},
  {name: "uniform", tag_type: "category"},
  {name: "sports", tag_type: "category"},
  {name: "essential", tag_type: "priority"}
])

puts "14. Creating sample items..."
items = Item.create!([
  {
    shop: shops[0],
    name: "Boys Soccer Jersey",
    description: "Official school soccer jersey for boys team",
    price: 45.00,
    quantity: 10,
    reserved: 0,
    status: 1, # active
    item_type_id: nil, # Not in your schema but referenced
    school: schools[0],
    brand: brands[0], # Nike
    size: item_sizes[2], # M
    item_condition: item_conditions[0], # New
    location: locations[0],
    province: provinces[2], # Gauteng
    gender: genders[0], # Boys
    meta: {color: "Red", size: "M"}
  },
  {
    shop: shops[0],
    name: "School Blazer",
    description: "Official school blazer with school crest",
    price: 120.00,
    quantity: 5,
    reserved: 0,
    status: 1,
    item_type_id: nil,
    school: schools[0],
    brand: brands[4], # SchoolBrand
    size: item_sizes[3], # L
    item_condition: item_conditions[0], # New
    location: locations[0],
    province: provinces[2], # Gauteng
    gender: genders[0], # Boys
    meta: {color: "Navy", size: "L"}
  },
  {
    shop: shops[1],
    name: "Girls Basketball Jersey",
    description: "Basketball jersey for girls team",
    price: 35.00,
    quantity: 8,
    reserved: 0,
    status: 1,
    item_type_id: nil,
    school: schools[2],
    brand: brands[1], # Adidas
    size: item_sizes[1], # S
    item_condition: item_conditions[1], # Used - Like New
    location: locations[2],
    province: provinces[8], # Western Cape
    gender: genders[1], # Girls
    meta: {color: "White", size: "S"}
  }
])

puts "15. Creating item tags..."
ItemTag.create!([
  {item: items[0], tag: tags[0]}, # soccer
  {item: items[0], tag: tags[2]}, # school team
  {item: items[0], tag: tags[4]}, # sports
  {item: items[1], tag: tags[3]}, # uniform
  {item: items[2], tag: tags[1]}, # basketball
  {item: items[2], tag: tags[2]}, # school team
  {item: items[2], tag: tags[4]}  # sports
])

puts "16. Creating sample orders..."
orders = Order.create!([
  {
    shop: shops[0],
    buyer: users[2],
    price: 45.00,
    total_amount: 50.00,
    order_status: 1, # completed
    payment_status: 1, # paid
    order_place_time: 2.days.ago,
    order_number: "ORD-#{Time.now.to_i}-#{SecureRandom.hex(3).upcase}"
  },
  {
    shop: shops[1],
    buyer: users[2],
    price: 35.00,
    total_amount: 40.00,
    order_status: 0, # pending
    payment_status: 0, # unpaid
    order_place_time: 1.day.ago,
    order_number: "ORD-#{Time.now.to_i+1}-#{SecureRandom.hex(3).upcase}"
  }
])

puts "17. Creating order items..."
OrderItem.create!([
  {
    order: orders[0],
    item: items[0],
    item_name: items[0].name,
    actual_price: items[0].price,
    total_price: items[0].price,
    quantity: 1,
    shop: shops[0]
  },
  {
    order: orders[1],
    item: items[2],
    item_name: items[2].name,
    actual_price: items[2].price,
    total_price: items[2].price,
    quantity: 1,
    shop: shops[1]
  }
])

puts "=" * 50
puts "Database seeded successfully!"
puts "=" * 50
puts "Summary:"
puts "- #{Province.count} provinces"
puts "- #{Town.count} towns"
puts "- #{Location.count} locations"
puts "- #{User.count} users"
puts "- #{Shop.count} shops"
puts "- #{Brand.count} brands"
puts "- #{ItemCondition.count} item conditions"
puts "- #{ItemSize.count} item sizes"
puts "- #{ItemColor.count} item colors"
puts "- #{Gender.count} genders"
puts "- #{School.count} schools"
puts "- #{Tag.count} tags"
puts "- #{Item.count} items"
puts "- #{Order.count} orders"
puts "=" * 50
puts "\nSample Data for Testing:"
puts "Shop Owner User ID: #{users[1].id}"
puts "Shop ID: #{shops[0].id}"
puts "Item IDs: #{items.map(&:id).join(', ')}"
puts "School ID: #{schools[0].id}"
puts "Brand ID: #{brands[0].id}"
puts "Size ID (M): #{item_sizes[2].id}"
puts "Gender ID (Boys): #{genders[0].id}"
puts "Condition ID (New): #{item_conditions[0].id}"
puts "Province ID (Gauteng): #{provinces[2].id}"
puts "Location ID (Johannesburg): #{locations[0].id}"
puts "=" * 50