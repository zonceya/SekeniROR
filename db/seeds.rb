# db/seeds.rb
# Complete corrected seed file for SkoolSwap

puts "🌱 Seeding database with South African school data..."

# ============================================
# 1. PROVINCES (South Africa)
# ============================================
puts "\n🏛️ Creating provinces..."
provinces = [
  { name: "Gauteng" },
  { name: "Western Cape" },
  { name: "KwaZulu-Natal" },
  { name: "Eastern Cape" },
  { name: "Free State" },
  { name: "Limpopo" },
  { name: "Mpumalanga" },
  { name: "North West" },
  { name: "Northern Cape" }
]

provinces.each do |province_data|
  Province.find_or_create_by!(name: province_data[:name])
end
puts "✅ Created #{Province.count} provinces"

# ============================================
# 2. TOWNS/LOCATIONS
# ============================================
puts "\n🏘️ Creating towns..."
towns_data = [
  # Gauteng
  { name: "Johannesburg", province: "Gauteng" },
  { name: "Pretoria", province: "Gauteng" },
  { name: "Soweto", province: "Gauteng" },
  { name: "Midrand", province: "Gauteng" },
  
  # Western Cape
  { name: "Cape Town", province: "Western Cape" },
  { name: "Stellenbosch", province: "Western Cape" },
  { name: "Paarl", province: "Western Cape" },
  { name: "George", province: "Western Cape" },
  
  # KwaZulu-Natal
  { name: "Durban", province: "KwaZulu-Natal" },
  { name: "Pietermaritzburg", province: "KwaZulu-Natal" },
  { name: "Newcastle", province: "KwaZulu-Natal" },
  
  # Eastern Cape
  { name: "Gqeberha", province: "Eastern Cape" }, # formerly Port Elizabeth
  { name: "East London", province: "Eastern Cape" },
  { name: "Mthatha", province: "Eastern Cape" }
]

towns_data.each do |town_data|
  province = Province.find_by(name: town_data[:province])
  Town.find_or_create_by!(name: town_data[:name], province_id: province.id)
end
puts "✅ Created #{Town.count} towns"

# ============================================
# 3. LOCATIONS (join table)
# ============================================
puts "\n📍 Creating locations..."
Town.all.each do |town|
  Location.find_or_create_by!(
    province: town.province.name,
    town_id: town.id,
    country: "South Africa"
  )
end
puts "✅ Created #{Location.count} locations"

# ============================================
# 4. GENDERS (by school phase)
# ============================================
puts "\n👥 Creating genders..."
genders_data = [
  # Foundation Phase (Grades R-3) - Ages 5-9
  { name: "Grade R", category: "foundation", exact_age: 5, display_name: "Grade R", gender_group: "all" },
  { name: "Grade 1", category: "foundation", exact_age: 6, display_name: "Grade 1", gender_group: "all" },
  { name: "Grade 2", category: "foundation", exact_age: 7, display_name: "Grade 2", gender_group: "all" },
  { name: "Grade 3", category: "foundation", exact_age: 8, display_name: "Grade 3", gender_group: "all" },
  
  # Intermediate Phase (Grades 4-7) - Ages 9-13
  { name: "Grade 4", category: "intermediate", exact_age: 9, display_name: "Grade 4", gender_group: "all" },
  { name: "Grade 5", category: "intermediate", exact_age: 10, display_name: "Grade 5", gender_group: "all" },
  { name: "Grade 6", category: "intermediate", exact_age: 11, display_name: "Grade 6", gender_group: "all" },
  { name: "Grade 7", category: "intermediate", exact_age: 12, display_name: "Grade 7", gender_group: "all" },
  
  # Senior Phase (Grades 8-9) - Ages 13-15
  { name: "Grade 8", category: "senior", exact_age: 13, display_name: "Grade 8", gender_group: "all" },
  { name: "Grade 9", category: "senior", exact_age: 14, display_name: "Grade 9", gender_group: "all" },
  
  # FET Phase (Grades 10-12) - Ages 15-18
  { name: "Grade 10", category: "fet", exact_age: 15, display_name: "Grade 10", gender_group: "all" },
  { name: "Grade 11", category: "fet", exact_age: 16, display_name: "Grade 11", gender_group: "all" },
  { name: "Grade 12", category: "fet", exact_age: 17, display_name: "Grade 12", gender_group: "all" },
  { name: "Matric", category: "fet", exact_age: 18, display_name: "Matric", gender_group: "all" },
  
  # Gender-specific (for uniform filtering)
  { name: "Boys", category: "gender", display_name: "Boys", gender_group: "boys" },
  { name: "Girls", category: "gender", display_name: "Girls", gender_group: "girls" },
  { name: "Unisex", category: "gender", display_name: "Unisex", gender_group: "unisex" }
]

genders_data.each do |gender_data|
  Gender.find_or_create_by!(name: gender_data[:name]) do |g|
    g.category = gender_data[:category]
    g.exact_age = gender_data[:exact_age]
    g.display_name = gender_data[:display_name]
    g.gender_group = gender_data[:gender_group]
  end
end
puts "✅ Created #{Gender.count} genders"

# ============================================
# 5. BRANDS
# ============================================
puts "\n🏷️ Creating brands..."
brands = [
  # School Uniform Brands
  "SchoolWear SA", "Student Prince", "Truworths", "Ackermans", "PEP",
  "Edcon", "Markham", "Jet", "Foschini", "Mr Price",
  
  # Sport Brands
  "Nike", "Adidas", "Puma", "Reebok", "New Balance",
  "Asics", "Umbro", "Castore", "Canterbury", "Blade",
  
  # Shoe Brands
  "Toughees", "Student Prince Shoes", "Bata", "Superga", "Vans",
  
  # Stationery Brands
  "Staedtler", "Koh-i-noor", "Pritt", "Bic", "Oxford",
  "King", "A4", "Elmers", "Faber-Castell", "Crayola",
  
  # School Bag Brands
  "JanSport", "Eastpak", "Safari", "Crocodile Creek", "Puma Bags"
]

brands.each do |brand_name|
  Brand.find_or_create_by!(name: brand_name)
end
puts "✅ Created #{Brand.count} brands"

# ============================================
# 6. ITEM CONDITIONS
# ============================================
puts "\n📊 Creating item conditions..."
conditions = [
  { name: "New with tags", description: "Brand new, never used, with original tags" },
  { name: "New without tags", description: "Brand new, never used, without tags" },
  { name: "Like new", description: "Used once or twice, in perfect condition" },
  { name: "Very good", description: "Lightly used, no visible wear" },
  { name: "Good", description: "Used but well maintained, normal wear" },
  { name: "Fair", description: "Visible wear, still functional" }
]

conditions.each do |condition|
  ItemCondition.find_or_create_by!(name: condition[:name]) do |c|
    c.description = condition[:description]
  end
end
puts "✅ Created #{ItemCondition.count} conditions"

# ============================================
# 7. COLORS
# ============================================
puts "\n🎨 Creating colors..."
colors = [
  "Navy Blue", "Royal Blue", "Sky Blue", "Black", "White", "Grey",
  "Charcoal", "Khaki", "Brown", "Maroon", "Burgundy", "Red",
  "Green", "Forest Green", "Olive", "Yellow", "Gold", "Orange",
  "Pink", "Purple", "Teal", "Turquoise", "Multicolor"
]

colors.each do |color_name|
  ItemColor.find_or_create_by!(name: color_name)
end
puts "✅ Created #{ItemColor.count} colors"

# ============================================
# 8. ITEM SIZES (by category)
# ============================================
puts "\n📏 Creating sizes..."
sizes = [
  # Clothing sizes
  "2-3 years", "3-4 years", "4-5 years", "5-6 years", "6-7 years", "7-8 years",
  "8-9 years", "9-10 years", "10-11 years", "11-12 years", "12-13 years", "13-14 years",
  "XS", "S", "M", "L", "XL", "XXL",
  
  # Numeric shoe sizes
  "Kids 8", "Kids 9", "Kids 10", "Kids 11", "Kids 12", "Kids 13",
  "Youth 1", "Youth 2", "Youth 3", "Youth 4", "Youth 5", "Youth 6",
  "Adult 3", "Adult 4", "Adult 5", "Adult 6", "Adult 7", "Adult 8", 
  "Adult 9", "Adult 10", "Adult 11", "Adult 12",
  
  # Stationery sizes
  "A4", "A5", "A6", "72 Page", "96 Page", "Hardcover",
  
  # Bag sizes
  "Small (15L)", "Medium (25L)", "Large (35L)", "Trolley"
]

sizes.each do |size_name|
  ItemSize.find_or_create_by!(name: size_name)
end
puts "✅ Created #{ItemSize.count} sizes"

# ============================================
# 9. MAIN CATEGORIES (with subcategories)
# ============================================
puts "\n📁 Creating main categories and subcategories..."

main_categories = [
  {
    name: "Uniforms",
    icon_name: "school",
    display_order: 1,
    subcategories: [
      "Shirts & Golfers",
      "Jerseys & Pullovers",
      "Blazers & Jackets",
      "Trousers & Shorts",
      "Skirts & Dresses",
      "Ties & Accessories",
      "Socks",
      "Sportswear"
    ]
  },
  {
    name: "Sport",
    icon_name: "sports",
    display_order: 2,
    subcategories: [
      "Rugby",
      "Soccer",
      "Cricket",
      "Hockey",
      "Netball",
      "Athletics",
      "Swimming",
      "Tennis",
      "Sportswear"
    ]
  },
  {
    name: "Stationery",
    icon_name: "edit",
    display_order: 3,
    subcategories: [
      "Books & Notebooks",
      "Pens & Pencils",
      "Art Supplies",
      "Glue & Adhesives",
      "Scissors & Cutting",
      "Files & Storage",
      "Calculators",
      "Mathematics Sets",
      "Paper & Wrapping"
    ]
  },
  {
    name: "Footwear",
    icon_name: "shoe",
    display_order: 4,
    subcategories: [
      "School Shoes - Leather",
      "School Shoes - Synthetic",
      "Takkies",
      "Sport-specific Shoes",
      "Toughees",
      "Student Prince Shoes"
    ]
  },
  {
    name: "Accessories",
    icon_name: "accessibility",
    display_order: 5,
    subcategories: [
      "School Bags",
      "Lunch Boxes",
      "Water Bottles",
      "Hair Accessories",
      "Badges & Patches",
      "Jewellery",
      "Scarves & Beanies"
    ]
  },
  {
    name: "Textbooks",
    icon_name: "menu_book",
    display_order: 6,
    subcategories: [
      "Mathematics",
      "Science",
      "English",
      "Afrikaans",
      "isiZulu",
      "History",
      "Geography",
      "Accounting",
      "Life Orientation"
    ]
  },
  {
    name: "Equipment",
    icon_name: "equipment",
    display_order: 7,
    subcategories: [
      "Sport Equipment",
      "Lab Coats",
      "Safety Goggles",
      "Protective Gear",
      "Musical Instruments"
    ]
  }
]

main_categories.each do |cat_data|
  main_cat = MainCategory.find_or_create_by!(name: cat_data[:name]) do |mc|
    mc.icon_name = cat_data[:icon_name]
    mc.display_order = cat_data[:display_order]
    mc.is_active = true
  end
  
  puts "  - #{main_cat.name}"
  
  cat_data[:subcategories].each_with_index do |sub_name, index|
    SubCategory.find_or_create_by!(
      main_category_id: main_cat.id,
      name: sub_name
    ) do |sub|
      sub.display_order = index + 1
      sub.is_active = true
    end
  end
end

puts "✅ Created #{MainCategory.count} main categories"
puts "✅ Created #{SubCategory.count} subcategories"

# ============================================
# 10. TAGS
# ============================================
puts "\n🏷️ Creating tags..."
tags = [
  # Phase tags
  { name: "Foundation Phase", tag_type: "phase" },
  { name: "Intermediate Phase", tag_type: "phase" },
  { name: "Senior Phase", tag_type: "phase" },
  { name: "FET Phase", tag_type: "phase" },
  { name: "Matric", tag_type: "phase" },
  
  # Grade tags
  { name: "Grade R", tag_type: "grade" },
  { name: "Grade 1", tag_type: "grade" },
  { name: "Grade 2", tag_type: "grade" },
  { name: "Grade 3", tag_type: "grade" },
  { name: "Grade 4", tag_type: "grade" },
  { name: "Grade 5", tag_type: "grade" },
  { name: "Grade 6", tag_type: "grade" },
  { name: "Grade 7", tag_type: "grade" },
  { name: "Grade 8", tag_type: "grade" },
  { name: "Grade 9", tag_type: "grade" },
  { name: "Grade 10", tag_type: "grade" },
  { name: "Grade 11", tag_type: "grade" },
  { name: "Grade 12", tag_type: "grade" },
  
  # Gender tags
  { name: "Boys", tag_type: "gender" },
  { name: "Girls", tag_type: "gender" },
  { name: "Unisex", tag_type: "gender" },
  
  # Season tags
  { name: "Summer", tag_type: "season" },
  { name: "Winter", tag_type: "season" },
  { name: "All Year", tag_type: "season" },
  
  # School type tags
  { name: "Primary School", tag_type: "school_type" },
  { name: "High School", tag_type: "school_type" },
  { name: "Combined School", tag_type: "school_type" }
]

tags.each do |tag_data|
  Tag.find_or_create_by!(name: tag_data[:name]) do |t|
    t.tag_type = tag_data[:tag_type]
  end
end
puts "✅ Created #{Tag.count} tags"

# ============================================
# 11. USERS & SHOPS
# ============================================
puts "\n👤 Creating users and shops..."

# Create test users if they don't exist
test_users = [
  { email: "buyer@example.com", name: "Test Buyer", mobile: "0712345678" },
  { email: "seller@example.com", name: "Test Seller", mobile: "0723456789" },
  { email: "parent@example.com", name: "Test Parent", mobile: "0734567890" }
]

test_users.each do |user_data|
  user = User.find_or_create_by!(email: user_data[:email]) do |u|
    u.name = user_data[:name]
    u.mobile = user_data[:mobile]
    u.auth_mode = "email"
    u.role = "user"
  end
  
  # Create shop for seller
  if user.email == "seller@example.com"
    Shop.find_or_create_by!(user_id: user.id) do |shop|
      shop.name = "Test Seller's Shop"
      shop.display_name = "Test Seller"
      shop.description = "Quality school items"
      shop.location = "Cape Town"
    end
  end
end

puts "✅ Created/updated #{User.count} users"
puts "✅ Created #{Shop.count} shops"

# ============================================
# 12. SCHOOLS (South African schools)
# ============================================
puts "\n🏫 Creating schools..."

schools_data = [
  # Gauteng
  { name: "Pretoria High School for Girls", province: "Gauteng", town: "Pretoria", school_type: "high" },
  { name: "King Edward VII School", province: "Gauteng", town: "Johannesburg", school_type: "high" },
  { name: "St Stithians College", province: "Gauteng", town: "Johannesburg", school_type: "combined" },
  { name: "Bryandale Primary School", province: "Gauteng", town: "Johannesburg", school_type: "primary" },
  
  # Western Cape
  { name: "Rondebosch Boys' High School", province: "Western Cape", town: "Cape Town", school_type: "high" },
  { name: "Wynberg Girls' High School", province: "Western Cape", town: "Cape Town", school_type: "high" },
  { name: "Bishops Diocesan College", province: "Western Cape", town: "Cape Town", school_type: "high" },
  { name: "Claremont Primary School", province: "Western Cape", town: "Cape Town", school_type: "primary" },
  
  # KwaZulu-Natal
  { name: "Hilton College", province: "KwaZulu-Natal", town: "Pietermaritzburg", school_type: "high" },
  { name: "Durban Girls' College", province: "KwaZulu-Natal", town: "Durban", school_type: "high" },
  { name: "Clifton School", province: "KwaZulu-Natal", town: "Durban", school_type: "combined" },
  
  # Eastern Cape
  { name: "Grey High School", province: "Eastern Cape", town: "Gqeberha", school_type: "high" },
  { name: "Diocesan School for Girls", province: "Eastern Cape", town: "Makhanda", school_type: "high" }
]

schools_data.each do |school_data|
  province = Province.find_by(name: school_data[:province])
  town = Town.find_by(name: school_data[:town])
  location = Location.find_by(town_id: town&.id)
  
  School.find_or_create_by!(name: school_data[:name]) do |s|
    s.province_id = province&.id
    s.location_id = location&.id
    s.school_type = school_data[:school_type]
  end
end
puts "✅ Created #{School.count} schools"

# ============================================
# 13. CREATE SAMPLE ITEMS
# ============================================
puts "\n📦 Creating sample items..."

# Get data as ActiveRecord relations (not arrays)
schools = School.all
shops = Shop.all
genders = Gender.all
conditions = ItemCondition.all
sizes = ItemSize.all
colors = ItemColor.all
brands = Brand.all

# Get specific genders
boys_genders = Gender.where(gender_group: "boys").or(Gender.where(category: "gender", name: "Boys"))
girls_genders = Gender.where(gender_group: "girls").or(Gender.where(category: "gender", name: "Girls"))
unisex_gender = Gender.find_by(name: "Unisex")

# Get categories
uniform_cat = MainCategory.find_by(name: "Uniforms")
sport_cat = MainCategory.find_by(name: "Sport")
stationery_cat = MainCategory.find_by(name: "Stationery")
footwear_cat = MainCategory.find_by(name: "Footwear")
accessories_cat = MainCategory.find_by(name: "Accessories")
textbook_cat = MainCategory.find_by(name: "Textbooks")
equipment_cat = MainCategory.find_by(name: "Equipment")

items_created = 0

# Helper function to create items
def create_sample_item(attributes)
  Item.create!(attributes)
  print "."
end

# UNIFORM ITEMS - Boys
puts "\n  Creating Boys Uniforms..."
10.times do |i|
  school = schools.sample
  gender = boys_genders.sample
  subcat = uniform_cat.sub_categories.sample
  
  create_sample_item(
    name: "#{school.name} #{subcat.name} - Boys",
    description: "Official school #{subcat.name.downcase} for boys",
    shop: shops.sample,
    school: school,
    main_category: uniform_cat,
    sub_category: subcat,
    gender: gender,
    brand: brands.sample,
    price: rand(150..800),
    total_quantity: rand(5..30),
    status: 1,
    location_id: school.location_id,
    province_id: school.province_id,
    item_condition_id: conditions.sample&.id,
    meta: { phase: "All Phases", season: ["Summer", "Winter"].sample }
  )
  items_created += 1
end

# UNIFORM ITEMS - Girls
puts "\n  Creating Girls Uniforms..."
10.times do |i|
  school = schools.sample
  gender = girls_genders.sample
  subcat = uniform_cat.sub_categories.sample
  
  create_sample_item(
    name: "#{school.name} #{subcat.name} - Girls",
    description: "Official school #{subcat.name.downcase} for girls",
    shop: shops.sample,
    school: school,
    main_category: uniform_cat,
    sub_category: subcat,
    gender: gender,
    brand: brands.sample,
    price: rand(150..800),
    total_quantity: rand(5..30),
    status: 1,
    location_id: school.location_id,
    province_id: school.province_id,
    item_condition_id: conditions.sample&.id,
    meta: { phase: "All Phases", season: ["Summer", "Winter"].sample }
  )
  items_created += 1
end

# SPORT ITEMS by sport type
puts "\n  Creating Sport Items..."
sports = ["Rugby", "Cricket", "Soccer", "Hockey", "Netball", "Athletics"]
sport_subcats = sport_cat.sub_categories.to_a

sports.each do |sport|
  subcat = sport_subcats.find { |s| s.name.include?(sport) } || sport_subcats.sample
  
  3.times do |i|
    school = schools.sample
    gender = [boys_genders.sample, girls_genders.sample].sample
    
    create_sample_item(
      name: "#{school.name} #{sport} #{['Jersey', 'Kit', 'Shorts', 'Socks'].sample}",
      description: "#{sport} gear for #{school.name}",
      shop: shops.sample,
      school: school,
      main_category: sport_cat,
      sub_category: subcat,
      gender: gender,
      brand: brands.where(name: ["Nike", "Adidas", "Puma"]).sample,
      price: rand(200..1200),
      total_quantity: rand(3..20),
      status: 1,
      location_id: school.location_id,
      province_id: school.province_id,
      item_condition_id: conditions.sample&.id,
      meta: { sport: sport.downcase, age_group: "All Ages" }
    )
    items_created += 1
  end
end

# STATIONERY ITEMS
puts "\n  Creating Stationery Items..."
stationery_items = [
  { name: "A4 Exercise Book 72 Page", price_range: 15..30 },
  { name: "A4 Exercise Book 96 Page", price_range: 20..40 },
  { name: "Hardcover Notebook A4", price_range: 40..80 },
  { name: "HB Pencils (Pack of 12)", price_range: 25..50 },
  { name: "Blue Pens (Pack of 10)", price_range: 30..60 },
  { name: "Pritt Glue Stick 43g", price_range: 15..25 },
  { name: "Mathematical Set", price_range: 45..90 },
  { name: "Scientific Calculator", price_range: 150..350 },
  { name: "30cm Ruler", price_range: 10..25 },
  { name: "Flip File 30 Pocket", price_range: 40..80 },
  { name: "Plastic Sleeves (Pack of 50)", price_range: 30..60 },
  { name: "Crayons 24 Pack", price_range: 25..50 }
]

stationery_items.each do |item_data|
  subcat = stationery_cat.sub_categories.sample
  school = schools.sample
  
  create_sample_item(
    name: item_data[:name],
    description: "High quality stationery",
    shop: shops.sample,
    school: school,
    main_category: stationery_cat,
    sub_category: subcat,
    gender: unisex_gender,
    brand: brands.where(name: ["Staedtler", "Bic", "Oxford", "King"]).sample,
    price: rand(item_data[:price_range]),
    total_quantity: rand(10..100),
    status: 1,
    location_id: school.location_id,
    province_id: school.province_id,
    item_condition_id: conditions.find_by(name: "New with tags")&.id,
    meta: { phase: "All Phases" }
  )
  items_created += 1
end

# FOOTWEAR ITEMS
puts "\n  Creating Footwear Items..."
footwear_types = [
  { name: "Black Leather School Shoes", brand: "Toughees", price_range: 300..600 },
  { name: "Black Synthetic School Shoes", brand: "Bata", price_range: 200..400 },
  { name: "White Takkies", brand: "Superga", price_range: 250..500 },
  { name: "Rugby Boots", brand: "Canterbury", price_range: 400..800 },
  { name: "Soccer Boots", brand: "Adidas", price_range: 500..1200 },
  { name: "Netball Trainers", brand: "Asics", price_range: 400..900 }
]

footwear_types.each do |footwear|
  subcat = footwear_cat.sub_categories.sample
  school = schools.sample
  brand = brands.find_by(name: footwear[:brand]) || brands.sample
  gender = [boys_genders.sample, girls_genders.sample].sample
  
  create_sample_item(
    name: footwear[:name],
    description: "Quality school footwear",
    shop: shops.sample,
    school: school,
    main_category: footwear_cat,
    sub_category: subcat,
    gender: gender,
    brand: brand,
    price: rand(footwear[:price_range]),
    total_quantity: rand(5..25),
    status: 1,
    location_id: school.location_id,
    province_id: school.province_id,
    item_condition_id: conditions.sample&.id,
    meta: { shoe_type: footwear[:name].include?("Leather") ? "leather" : "synthetic" }
  )
  items_created += 1
end

# ACCESSORIES ITEMS
puts "\n  Creating Accessories Items..."
accessories_list = [
  { name: "School Backpack - Small", price_range: 200..400 },
  { name: "School Backpack - Medium", price_range: 300..500 },
  { name: "School Backpack - Large", price_range: 400..700 },
  { name: "Trolley Bag", price_range: 500..900 },
  { name: "Insulated Lunch Box", price_range: 80..200 },
  { name: "Sports Water Bottle", price_range: 50..150 },
  { name: "Pencil Case", price_range: 30..80 },
  { name: "Library Bag", price_range: 40..90 },
  { name: "School Scarf", price_range: 60..150 },
  { name: "School Beanie", price_range: 50..120 }
]

accessories_list.each do |acc|
  subcat = accessories_cat.sub_categories.sample
  school = schools.sample
  
  create_sample_item(
    name: acc[:name],
    description: "Essential school accessory",
    shop: shops.sample,
    school: school,
    main_category: accessories_cat,
    sub_category: subcat,
    gender: unisex_gender,
    brand: brands.where(name: ["JanSport", "Eastpak", "Safari"]).sample,
    price: rand(acc[:price_range]),
    total_quantity: rand(5..30),
    status: 1,
    location_id: school.location_id,
    province_id: school.province_id,
    item_condition_id: conditions.find_by(name: "New with tags")&.id,
    meta: { type: acc[:name].include?("Bag") ? "bag" : "accessory" }
  )
  items_created += 1
end

puts "\n✅ Created #{items_created} total items"

# ============================================
# 14. ASSIGN SCHOOL TO TEST USER
# ============================================
puts "\n🔗 Assigning school to test user..."
test_user = User.find_by(email: "buyer@example.com")
if test_user
  school = School.find_by(name: "Claremont Primary School") || School.first
  UserSchool.find_or_create_by!(
    user_id: test_user.id,
    school_id: school.id
  )
  puts "✅ Assigned #{test_user.name} to #{school.name}"
end

# ============================================
# 15. CREATE SOME VIEWS FOR TRENDING
# ============================================
puts "\n👁️ Creating sample item views..."
items = Item.all.to_a
test_user = User.find_by(email: "buyer@example.com")

if test_user && items.any?
  50.times do
    item = items.sample
    UserItemView.create!(
      user_id: test_user.id,
      item_id: item.id,
      school_id: item.school_id,
      source: ["home", "search", "category"].sample,
      view_count: rand(1..10),
      created_at: rand(1..7).days.ago
    )
  end
  puts "✅ Created sample views for trending"
end

puts "\n" + "=" * 50
puts "🎉 SEEDING COMPLETED SUCCESSFULLY!"
puts "=" * 50
puts "\n📊 Summary:"
puts "  - #{Province.count} provinces"
puts "  - #{Town.count} towns"
puts "  - #{Location.count} locations"
puts "  - #{Gender.count} genders"
puts "  - #{Brand.count} brands"
puts "  - #{ItemCondition.count} conditions"
puts "  - #{ItemColor.count} colors"
puts "  - #{ItemSize.count} sizes"
puts "  - #{MainCategory.count} main categories"
puts "  - #{SubCategory.count} subcategories"
puts "  - #{Tag.count} tags"
puts "  - #{User.count} users"
puts "  - #{Shop.count} shops"
puts "  - #{School.count} schools"
puts "  - #{Item.count} items"
puts "  - #{UserItemView.count} item views"