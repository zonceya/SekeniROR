# Clear existing data safely
ActiveRecord::Base.connection.disable_referential_integrity do
  tables = ActiveRecord::Base.connection.tables - ['schema_migrations', 'ar_internal_metadata']
  tables.each do |table|
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table} RESTART IDENTITY CASCADE")
  end
end

# Helper method for unique order numbers
def generate_order_number
  "ORD-#{Time.now.to_i}-#{SecureRandom.hex(3).upcase}"
end

# Create basic records first
provinces = Province.create!([
  {name: "Eastern Cape"}, {name: "Free State"}, {name: "Gauteng"},
  {name: "KwaZulu-Natal"}, {name: "Limpopo"}, {name: "Mpumalanga"},
  {name: "North West"}, {name: "Northern Cape"}, {name: "Western Cape"}
])

towns = Town.create!([
  {name: "Johannesburg", province: provinces[2]},
  {name: "Pretoria", province: provinces[2]},
  {name: "Cape Town", province: provinces[8]},
  {name: "Durban", province: provinces[3]},
  {name: "Bloemfontein", province: provinces[1]}
])

locations = Location.create!([
  {province: "Gauteng", town: towns[0]},
  {province: "Gauteng", town: towns[1]},
  {province: "Western Cape", town: towns[2]},
  {province: "KwaZulu-Natal", town: towns[3]},
  {province: "Free State", town: towns[4]}
])

schools = School.create!([
  {name: "Johannesburg Primary School", location: locations[0], school_type: "primary", province: provinces[2]},
  {name: "Pretoria High School", location: locations[1], school_type: "high", province: provinces[2]},
  {name: "Cape Town Primary School", location: locations[2], school_type: "primary", province: provinces[8]},
  {name: "Durban High School", location: locations[3], school_type: "high", province: provinces[3]},
  {name: "Bloemfontein Combined School", location: locations[4], school_type: "combined", province: provinces[1]}
])

# Create users with profiles
users = User.create!([
  {name: "System Admin", email: "admin@schoolsystem.com", role: "admin", password: "Admin@123", status: true},
  {name: "School Admin", email: "schooladmin@schoolsystem.com", role: "school_admin", password: "School@123", status: true},
  {name: "Teacher User", email: "teacher@schoolsystem.com", role: "teacher", password: "Teacher@123", status: true},
  {name: "Parent User", email: "parent@schoolsystem.com", role: "parent", password: "Parent@123", status: true},
  {name: "Student User", email: "student@schoolsystem.com", role: "student", password: "Student@123", status: true}
])

users.each do |user|
  Profile.create!(
    user: user,
    profile_picture: "default.png",
    mobile: "+27#{rand(10**9).to_s.rjust(9, '0')}"
  )
end

# Create shops and configurations - WITH EXPLICIT IDs
shops = Shop.create!([
  {id: 1, user: users[1], name: "#{schools[0].name} Store", description: "Official store for #{schools[0].name}", location: locations[0].province},
  {id: 2, user: users[2], name: "Teacher's Resale Shop", description: "Gently used school items", location: locations[1].province}
])

shops.each do |shop|
  Configuration.create!(
    shop: shop,
    delivery_price: rand(20..100),
    is_delivery_available: [true, false].sample,
    is_order_taken: true
  )
end

# Create inventory-related records
item_groups = ItemGroup.create!([
  {name: "Uniforms", description: "School uniforms and related items"},
  {name: "Stationery", description: "Writing and classroom materials"},
  {name: "Books", description: "Textbooks and reading materials"},
  {name: "Sports", description: "Sports equipment and attire"},
  {name: "Other", description: "Miscellaneous school items"}
])

item_types = ItemType.create!([
  {group: item_groups[0], name: "Shirt", description: "School shirts"},
  {group: item_groups[0], name: "Pants", description: "School pants"},
  {group: item_groups[0], name: "Skirt", description: "School skirts"},
  {group: item_groups[0], name: "Blazer", description: "School blazers"},
  {group: item_groups[1], name: "Pens", description: "Writing pens"},
  {group: item_groups[1], name: "Notebooks", description: "Exercise books"},
  {group: item_groups[2], name: "Textbook", description: "Curriculum textbooks"},
  {group: item_groups[3], name: "Tracksuit", description: "Sports tracksuits"},
  {group: item_groups[3], name: "Tennis Shoes", description: "Sports shoes"}
])

brands = Brand.create!([
  {name: "SchoolBrand"}, {name: "EduWear"}, {name: "ScholarGear"},
  {name: "Academix"}, {name: "LearnRight"}
])

item_conditions = ItemCondition.create!([
  {name: "New", description: "Brand new item"},
  {name: "Like New", description: "Gently used, looks new"},
  {name: "Good", description: "Used but in good condition"},
  {name: "Fair", description: "Shows signs of wear"},
  {name: "Poor", description: "Heavily used but functional"}
])

item_sizes = ItemSize.create!([
  {name: "XXS"}, {name: "XS"}, {name: "S"}, {name: "M"},
  {name: "L"}, {name: "XL"}, {name: "XXL"}, {name: "Age 5-6"},
  {name: "Age 7-8"}, {name: "Age 9-10"}, {name: "Age 11-12"}, {name: "Age 13+"}
])

item_colors = ItemColor.create!([
  {name: "White"}, {name: "Black"}, {name: "Navy"},
  {name: "Grey"}, {name: "Maroon"}, {name: "Green"}
])

genders = Gender.create!([
  {name: "Boys", category: "standard", display_name: "Boys", gender_group: "male"},
  {name: "Girls", category: "standard", display_name: "Girls", gender_group: "female"},
  {name: "Unisex", category: "standard", display_name: "Unisex", gender_group: "unisex"},
  {name: "Age 5", category: "age", exact_age: 5, display_name: "Age 5", gender_group: "unisex"},
  {name: "Age 6", category: "age", exact_age: 6, display_name: "Age 6", gender_group: "unisex"}
])

# Create items with variants and stock
items = Item.create!([
  {
    shop: shops[0],
    name: "School Shirt",
    description: "White school shirt with school logo",
    icon: "shirt.png",
    cover_photo: "shirt_cover.jpg",
    status: 1,
    item_type: item_types[0],
    school: schools[0],
    brand: brands[0],
    size: item_sizes[3], # M
    price: 150.00,
    quantity: 50,
    item_condition: item_conditions[0], # New
    location: locations[0],
    province: provinces[2], # Gauteng
    gender: genders[0] # Boys
  },
  {
    shop: shops[0],
    name: "School Pants",
    description: "Grey school pants",
    icon: "pants.png",
    cover_photo: "pants_cover.jpg",
    status: 1,
    item_type: item_types[1],
    school: schools[0],
    brand: brands[1],
    size: item_sizes[4], # L
    price: 200.00,
    quantity: 30,
    item_condition: item_conditions[0], # New
    location: locations[0],
    province: provinces[2], # Gauteng
    gender: genders[0] # Boys
  },
  {
    shop: shops[1],
    name: "Mathematics Textbook",
    description: "Grade 10 Mathematics textbook",
    icon: "math_book.png",
    cover_photo: "math_cover.jpg",
    status: 1,
    item_type: item_types[6], # Textbook
    school: schools[1],
    brand: brands[2],
    price: 250.00,
    quantity: 15,
    item_condition: item_conditions[2], # Good
    location: locations[1],
    province: provinces[2] # Gauteng
  }
])

item_variants = ItemVariant.create!([
  {
    item: items[0],
    item_type: "color",
    variant_name: "Color",
    variant_value: "White",
    actual_price: 150.00,
    stock_availability: 50,
    color: item_colors[0] # White
  },
  {
    item: items[1],
    item_type: "size",
    variant_name: "Size",
    variant_value: "L",
    actual_price: 200.00,
    stock_availability: 30
  }
])

ItemStock.create!([
  {
    item_variant: item_variants[0],
    location: locations[0],
    condition: item_conditions[0], # New
    quantity: 50,
    meta: { notes: "Primary warehouse stock" }
  },
  {
    item_variant: item_variants[1],
    location: locations[0],
    condition: item_conditions[0], # New
    quantity: 30,
    meta: { notes: "Primary warehouse stock" }
  }
])

# Create tags and associations
tags = Tag.create!([
  {name: "uniform", tag_type: "category"},
  {name: "clothing", tag_type: "category"},
  {name: "textbook", tag_type: "category"},
  {name: "essential", tag_type: "priority"},
  {name: "optional", tag_type: "priority"}
])

ItemTag.create!([
  {item: items[0], tag: tags[0]}, # uniform
  {item: items[0], tag: tags[1]}, # clothing
  {item: items[1], tag: tags[0]}, # uniform
  {item: items[1], tag: tags[1]}, # clothing
  {item: items[2], tag: tags[2]}  # textbook
])

# Create orders and related records
orders = Order.create!([
  {
    shop: shops[0],
    buyer: users[3], # parent
    price: 350.00,
    order_status: 1, # completed
    payment_status: 1, # paid
    order_place_time: 2.days.ago,
    total_amount: 400.00,
    order_number: generate_order_number
  },
  {
    shop: shops[0],
    buyer: users[2], # teacher
    price: 250.00,
    order_status: 0, # pending
    payment_status: 0, # unpaid
    order_place_time: 1.day.ago,
    total_amount: 300.00,
    order_number: generate_order_number
  }
])

order_items = OrderItem.create!([
  {
    order: orders[0],
    item: items[0],
    item_name: items[0].name,
    item_variant: item_variants[0],
    actual_price: items[0].price,
    total_price: items[0].price * 2,
    quantity: 2,
    shop: shops[0]
  },
  {
    order: orders[1],
    item: items[1],
    item_name: items[1].name,
    item_variant: item_variants[1],
    actual_price: items[1].price,
    total_price: items[1].price,
    quantity: 1,
    shop: shops[0]
  }
])

# Create other associations
Hold.create!(
  item: items[0],
  user: users[3], # parent
  order: orders[0],
  quantity: 2,
  expires_at: 1.week.from_now,
  status: "completed"
)

Favorite.create!([
  {user: users[4], item: items[0]}, # student
  {user: users[3], item: items[2]}  # parent
])

PurchaseHistory.create!([
  {user: users[3], item: items[0]}, # parent
  {user: users[2], item: items[1]}  # teacher
])

Promotion.create!(
  item: items[0],
  promo_type: "discount",
  start_date: Time.current,
  end_date: 1.month.from_now,
  shop: shops[0],
  title: "Back to School Sale",
  description: "20% off all uniforms",
  is_active: true
)

ReturnRequest.create!(
  order_item: order_items[0],
  reason: "Wrong size",
  status: "pending"
)

UserSchool.create!([
  {user: users[1], school: schools[0]}, # school admin
  {user: users[2], school: schools[0]}, # teacher
  {user: users[3], school: schools[0]}, # parent
  {user: users[4], school: schools[0]}  # student
])

MyStorePurchase.create!(
  shop: shops[0],
  pending_orders: 1,
  completed_orders: 1,
  canceled_orders: 0,
  item_count: 2,
  revenue: 350.00
)

Rating.create!(
  shop: shops[0],
  rating: 4.5,
  user_count: 2
)

puts "Database seeded successfully with:"
puts "- #{Province.count} provinces"
puts "- #{Town.count} towns"
puts "- #{Location.count} locations"
puts "- #{School.count} schools"
puts "- #{User.count} users"
puts "- #{Item.count} items"
puts "- #{Order.count} orders"