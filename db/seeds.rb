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
  {province: "Gauteng", state_or_region: "Johannesburg", country: "South Africa", town_id: towns[0].id},
  {province: "Gauteng", state_or_region: "Pretoria", country: "South Africa", town_id: towns[1].id},
  {province: "Western Cape", state_or_region: "Cape Town", country: "South Africa", town_id: towns[2].id},
  {province: "KwaZulu-Natal", state_or_region: "Durban", country: "South Africa", town_id: towns[3].id},
  {province: "Free State", state_or_region: "Bloemfontein", country: "South Africa", town_id: towns[4].id}
])

puts "4. Creating users..."
users = User.create!([
  {name: "System Admin", email: "admin@schoolsystem.com", password_digest: BCrypt::Password.create("Admin@123"), role: "admin", status: true},
  {name: "Shop Owner", email: "shopowner@example.com", password_digest: BCrypt::Password.create("Shop@123"), role: "user", status: true},
  {name: "Buyer User", email: "buyer@example.com", password_digest: BCrypt::Password.create("Buyer@123"), role: "user", status: true}
])

puts "5. Creating profiles..."
profiles = []
users.each do |user|
  profiles << Profile.create!(
    user: user,
    mobile: "+27#{rand(10**9).to_s.rjust(9, '0')}"
  )
end

puts "6. Creating shops..."
shops = Shop.create!([
  {user_id: users[1].id, name: "Johannesburg School Store", description: "Official store for Johannesburg schools", location: "Gauteng"},
  {user_id: users[0].id, name: "Test Shop", description: "Test shop for development", location: "Western Cape"}
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

puts "14. Creating main categories..."
main_categories = MainCategory.create!([
  {name: "Textbooks & Study Materials", description: "Academic books and study resources", is_active: true, display_order: 0},
  {name: "Electronics & Gadgets", description: "Laptops, phones, calculators, and other electronic devices", icon_name: "electronics-icon", display_order: 1, is_active: true},
  {name: "Clothing & Accessories", description: "Uniforms, casual wear, bags, and accessories", icon_name: "clothing-icon", display_order: 2, is_active: true},
  {name: "Stationery & Supplies", description: "Notebooks, pens, art supplies, and study materials", icon_name: "stationery-icon", display_order: 3, is_active: true}
])

puts "15. Creating sub categories..."
sub_categories = SubCategory.create!([
  {name: "Textbooks", main_category_id: main_categories[0].id, is_active: true},
  {name: "Study Guides", main_category_id: main_categories[0].id, is_active: true},
  {name: "Laptops", main_category_id: main_categories[1].id, is_active: true},
  {name: "Calculators", main_category_id: main_categories[1].id, is_active: true},
  {name: "Uniforms", main_category_id: main_categories[2].id, is_active: true},
  {name: "Sports Wear", main_category_id: main_categories[2].id, is_active: true},
  {name: "Notebooks", main_category_id: main_categories[3].id, is_active: true},
  {name: "Pens & Pencils", main_category_id: main_categories[3].id, is_active: true}
])

puts "16. Creating item types (linked to main categories)..."
# ItemType belongs to MainCategory directly
item_types = ItemType.create!([
  {name: "Soccer Jersey", main_category_id: main_categories[2].id, is_active: true}, # Clothing
  {name: "Basketball Jersey", main_category_id: main_categories[2].id, is_active: true}, # Clothing
  {name: "School Blazer", main_category_id: main_categories[2].id, is_active: true}, # Clothing
  {name: "Math Textbook", main_category_id: main_categories[0].id, is_active: true}, # Textbooks
  {name: "Scientific Calculator", main_category_id: main_categories[1].id, is_active: true} # Electronics
])

puts "17. Creating sample items..."
items = []

# Item 1 - Boys Soccer Jersey
item1 = Item.create!(
  shop_id: shops[0].id,
  name: "Boys Soccer Jersey",
  description: "Official school soccer jersey for boys team",
  price: 45.00,
  total_quantity: 10,
  total_reserved: 0,
  status: 1, # active
  school_id: schools[0].id,
  brand_id: brands[0].id, # Nike
  item_type_id: item_types[0].id, # Soccer Jersey
  main_category_id: main_categories[2].id, # Clothing
  sub_category_id: sub_categories[5].id, # Sports Wear
  location_id: locations[0].id,
  province_id: provinces[2].id, # Gauteng
  gender_id: genders[0].id, # Boys
  item_condition_id: item_conditions[0].id, # New
  min_price: 45.00,
  max_price: 45.00,
  available_variants_count: 1,
  meta: {color: "Red", size: "M"}
)
items << item1

# Item 2 - School Blazer
item2 = Item.create!(
  shop_id: shops[0].id,
  name: "School Blazer",
  description: "Official school blazer with school crest",
  price: 120.00,
  total_quantity: 5,
  total_reserved: 0,
  status: 1,
  school_id: schools[0].id,
  brand_id: brands[4].id, # SchoolBrand
  item_type_id: item_types[2].id, # School Blazer
  main_category_id: main_categories[2].id, # Clothing
  sub_category_id: sub_categories[4].id, # Uniforms
  location_id: locations[0].id,
  province_id: provinces[2].id, # Gauteng
  gender_id: genders[0].id, # Boys
  item_condition_id: item_conditions[0].id, # New
  min_price: 120.00,
  max_price: 120.00,
  available_variants_count: 1,
  meta: {color: "Navy", size: "L"}
)
items << item2

# Item 3 - Girls Basketball Jersey
item3 = Item.create!(
  shop_id: shops[1].id,
  name: "Girls Basketball Jersey",
  description: "Basketball jersey for girls team",
  price: 35.00,
  total_quantity: 8,
  total_reserved: 0,
  status: 1,
  school_id: schools[2].id,
  brand_id: brands[1].id, # Adidas
  item_type_id: item_types[1].id, # Basketball Jersey
  main_category_id: main_categories[2].id, # Clothing
  sub_category_id: sub_categories[5].id, # Sports Wear
  location_id: locations[2].id,
  province_id: provinces[8].id, # Western Cape
  gender_id: genders[1].id, # Girls
  item_condition_id: item_conditions[1].id, # Used - Like New
  min_price: 35.00,
  max_price: 35.00,
  available_variants_count: 1,
  meta: {color: "White", size: "S"}
)
items << item3

puts "Created #{items.count} items"

puts "18. Creating item tags..."
ItemTag.create!([
  {item_id: items[0].id, tag_id: tags[0].id}, # soccer
  {item_id: items[0].id, tag_id: tags[2].id}, # school team
  {item_id: items[0].id, tag_id: tags[4].id}, # sports
  {item_id: items[1].id, tag_id: tags[3].id}, # uniform
  {item_id: items[2].id, tag_id: tags[1].id}, # basketball
  {item_id: items[2].id, tag_id: tags[2].id}, # school team
  {item_id: items[2].id, tag_id: tags[4].id}  # sports
])

puts "19. Creating item variants..."
# Create variants for sizes/colors
items.each_with_index do |item, index|
  ItemVariant.create!(
    item_id: item.id,
    size_id: index == 0 ? item_sizes[2].id : (index == 1 ? item_sizes[3].id : item_sizes[1].id),
    color_id: index == 0 ? item_colors[1].id : (index == 1 ? item_colors[3].id : item_colors[0].id),
    quantity: item.total_quantity,
    price: item.price
  )
end

puts "20. Creating sample orders..."
orders = Order.create!([
  {
    shop_id: shops[0].id,
    buyer_id: users[2].id,
    price: 45.00,
    total_amount: 50.00,
    order_status: 1, # completed
    payment_status: 1, # paid
    order_place_time: 2.days.ago,
    order_number: "ORD-#{Time.now.to_i}-#{SecureRandom.hex(3).upcase}"
  },
  {
    shop_id: shops[1].id,
    buyer_id: users[2].id,
    price: 35.00,
    total_amount: 40.00,
    order_status: 0, # pending
    payment_status: 0, # unpaid
    order_place_time: 1.day.ago,
    order_number: "ORD-#{Time.now.to_i+1}-#{SecureRandom.hex(3).upcase}"
  }
])

puts "21. Creating order items..."
OrderItem.create!([
  {
    order_id: orders[0].id,
    item_id: items[0].id,
    item_name: items[0].name,
    actual_price: items[0].price,
    total_price: items[0].price,
    quantity: 1,
    shop_id: shops[0].id
  },
  {
    order_id: orders[1].id,
    item_id: items[2].id,
    item_name: items[2].name,
    actual_price: items[2].price,
    total_price: items[2].price,
    quantity: 1,
    shop_id: shops[1].id
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
puts "- #{Profile.count} profiles"
puts "- #{Shop.count} shops"
puts "- #{Brand.count} brands"
puts "- #{ItemCondition.count} item conditions"
puts "- #{ItemSize.count} item sizes"
puts "- #{ItemColor.count} item colors"
puts "- #{Gender.count} genders"
puts "- #{School.count} schools"
puts "- #{Tag.count} tags"
puts "- #{MainCategory.count} main categories"
puts "- #{SubCategory.count} sub categories"
puts "- #{ItemType.count} item types"
puts "- #{Item.count} items"
puts "- #{ItemVariant.count} item variants"
puts "- #{Order.count} orders"
puts "- #{OrderItem.count} order items"
puts "=" * 50