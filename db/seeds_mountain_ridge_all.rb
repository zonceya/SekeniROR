# db/seeds_mountain_ridge_all.rb
puts "🏫 Starting Mountain Ridge High Complete Seeding..."
puts "=" * 60

CDN_BASE = "https://cdn.skoolswap.co.za"
SCHOOL_NAME = "Mountain Ridge High"

# ============================================
# 1. FIND OR CREATE SCHOOL
# ============================================
puts "1. Setting up school and shop..."

school = School.find_or_create_by!(name: SCHOOL_NAME) do |s|
  province = Province.find_or_create_by!(name: "Western Cape")
  location = Location.find_or_create_by!(
    province: "Western Cape",
    country: "South Africa"
  )
  s.location_id = location.id
  s.province_id = province.id
  s.school_type = "High School"
end
puts "✅ School: #{school.name} (ID: #{school.id})"

# Create user and shop
school_email = "mountainridge@example.com"
user = User.find_or_create_by!(email: school_email) do |u|
  u.name = SCHOOL_NAME
  u.password_digest = BCrypt::Password.create("password123")
  u.role = "user"
  u.status = true
  u.auth_mode = "default_auth_mode"
end
puts "✅ User: #{user.email} (ID: #{user.id})"

shop = Shop.find_or_create_by!(user_id: user.id) do |s|
  s.name = "#{SCHOOL_NAME} Shop"
  s.description = "Official shop for #{SCHOOL_NAME}"
  s.display_name = "#{SCHOOL_NAME} Shop"
  s.location = "Cape Town"
end
puts "✅ Shop: #{shop.name} (ID: #{shop.id})"

# ============================================
# 2. ENSURE CATEGORIES EXIST
# ============================================
puts "2. Ensuring categories exist..."

# Main Categories
sport_category = MainCategory.find_or_create_by!(name: "Sport") do |mc|
  mc.description = "Sports equipment and uniforms"
  mc.icon_name = "sports"
  mc.is_active = true
  mc.display_order = 1
end

uniforms_category = MainCategory.find_or_create_by!(name: "Uniforms") do |mc|
  mc.description = "School uniforms and apparel"
  mc.icon_name = "school"
  mc.is_active = true
  mc.display_order = 2
end

accessories_category = MainCategory.find_or_create_by!(name: "Accessories") do |mc|
  mc.description = "School accessories and bags"
  mc.icon_name = "accessibility"
  mc.is_active = true
  mc.display_order = 3
end

# Sub Categories - Sport
sport_subcategories = {}
["Swimming", "Soccer", "Rugby", "Athletics", "Sportswear"].each do |name|
  sport_subcategories[name] = SubCategory.find_or_create_by!(
    name: name,
    main_category_id: sport_category.id
  ) do |sc|
    sc.description = "#{name} items"
    sc.is_active = true
    sc.display_order = sport_subcategories.keys.count + 1
  end
end

# Sub Categories - Uniforms
uniform_subcategories = {}
["Sportswear", "Jackets & Hoodies", "Shirts & Golfers", "Skirts & Dresses", "Accessories"].each do |name|
  uniform_subcategories[name] = SubCategory.find_or_create_by!(
    name: name,
    main_category_id: uniforms_category.id
  ) do |sc|
    sc.description = "#{name} items"
    sc.is_active = true
    sc.display_order = uniform_subcategories.keys.count + 1
  end
end

# Sub Categories - Accessories
accessory_subcategories = {}
["Bags", "Scarves & Beanies", "Accessories"].each do |name|
  accessory_subcategories[name] = SubCategory.find_or_create_by!(
    name: name,
    main_category_id: accessories_category.id
  ) do |sc|
    sc.description = "#{name} items"
    sc.is_active = true
    sc.display_order = accessory_subcategories.keys.count + 1
  end
end

# ============================================
# 3. CREATE BRANDS, SIZES, COLORS, GENDERS, CONDITIONS
# ============================================
puts "3. Creating brands, sizes, colors, genders, conditions..."

brands = {
  "Nike" => Brand.find_or_create_by!(name: "Nike"),
  "Adidas" => Brand.find_or_create_by!(name: "Adidas"),
  "Puma" => Brand.find_or_create_by!(name: "Puma"),
  "Speedo" => Brand.find_or_create_by!(name: "Speedo"),
  "Arena" => Brand.find_or_create_by!(name: "Arena")
}

sizes = {
  "S" => ItemSize.find_or_create_by!(name: "S"),
  "M" => ItemSize.find_or_create_by!(name: "M"),
  "L" => ItemSize.find_or_create_by!(name: "L"),
  "XL" => ItemSize.find_or_create_by!(name: "XL"),
  "XXL" => ItemSize.find_or_create_by!(name: "XXL"),
  "One Size" => ItemSize.find_or_create_by!(name: "One Size")
}

colors = {
  "Red" => ItemColor.find_or_create_by!(name: "Red"),
  "Blue" => ItemColor.find_or_create_by!(name: "Blue"),
  "White" => ItemColor.find_or_create_by!(name: "White"),
  "Black" => ItemColor.find_or_create_by!(name: "Black"),
  "Navy" => ItemColor.find_or_create_by!(name: "Navy"),
  "Yellow" => ItemColor.find_or_create_by!(name: "Yellow"),
  "Grey" => ItemColor.find_or_create_by!(name: "Grey"),
  "Green" => ItemColor.find_or_create_by!(name: "Green"),
  "Purple" => ItemColor.find_or_create_by!(name: "Purple"),
  "Orange" => ItemColor.find_or_create_by!(name: "Orange")
}

genders = {
  "Boys" => Gender.find_or_create_by!(name: "Boys") { |g| g.category = "standard"; g.display_name = "Boys"; g.gender_group = "male" },
  "Girls" => Gender.find_or_create_by!(name: "Girls") { |g| g.category = "standard"; g.display_name = "Girls"; g.gender_group = "female" },
  "Unisex" => Gender.find_or_create_by!(name: "Unisex") { |g| g.category = "standard"; g.display_name = "Unisex"; g.gender_group = "unisex" }
}

new_condition = ItemCondition.find_or_create_by!(name: "New") do |ic|
  ic.description = "Brand new item"
end

# ============================================
# 4. CREATE ALL ITEMS WITH PROPER V2 HANDLING
# ============================================
puts "4. Creating all items with v2 handling..."
puts ""

# Helper method to create item with v2 handling
def create_item_with_images(item_data, school, shop, cdn_base, category, subcategory)
  folder = item_data[:folder]
  image_prefix = item_data[:image_prefix]
  
  # Build URLs
  cover_url = "#{cdn_base}/schools_demo/mountain-ridge-high/#{folder}/#{image_prefix}_v1.webp"
  
  # Check if v2 exists (we'll check by trying to construct the URL)
  has_v2 = item_data[:has_v2] || false
  
  if has_v2
    additional_url = "#{cdn_base}/schools_demo/mountain-ridge-high/#{folder}/#{image_prefix}_v2.webp"
  else
    additional_url = cover_url
  end
  
  # Find or create item
  existing_item = Item.find_by(
    name: item_data[:name],
    school_id: school.id
  )
  
  if existing_item
    existing_item.update!(
      description: item_data[:description],
      price: item_data[:price],
      label: item_data[:label],
      cover_photo: cover_url,
      additional_photo: additional_url,
      label_photo: cover_url,
      shop_id: shop.id,
      main_category_id: category.id,
      sub_category_id: subcategory.id,
      brand_id: item_data[:brand]&.id,
      gender_id: item_data[:gender]&.id,
      total_quantity: item_data[:quantity],
      min_price: item_data[:price],
      max_price: item_data[:price],
      status: 1,
      deleted: false,
      updated_at: Time.current
    )
    item = existing_item
    status = "🔄 Updated"
  else
    item = Item.create!(
      id: SecureRandom.uuid,
      name: item_data[:name],
      description: item_data[:description],
      price: item_data[:price],
      label: item_data[:label],
      cover_photo: cover_url,
      additional_photo: additional_url,
      label_photo: cover_url,
      shop_id: shop.id,
      school_id: school.id,
      main_category_id: category.id,
      sub_category_id: subcategory.id,
      brand_id: item_data[:brand]&.id,
      gender_id: item_data[:gender]&.id,
      total_quantity: item_data[:quantity],
      total_reserved: 0,
      min_price: item_data[:price],
      max_price: item_data[:price],
      status: 1,
      deleted: false,
      view_count: 0,
      created_at: Time.current,
      updated_at: Time.current
    )
    status = "✅ Created"
  end
  
  # Create variant
  variant_attributes = { item_id: item.id, condition_id: new_condition.id }
  variant_attributes[:size_id] = item_data[:size]&.id if item_data[:size].present?
  variant_attributes[:color_id] = item_data[:color]&.id if item_data[:color].present?
  
  variant = ItemVariant.find_or_create_by!(variant_attributes) do |v|
    v.price = item_data[:price]
    v.quantity = item_data[:quantity]
    v.reserved = 0
    v.is_active = true
    v.sku = "#{image_prefix.upcase}-#{SecureRandom.hex(4)}".upcase
    v.metadata = { color: item_data[:color]&.name || "N/A", size: item_data[:size]&.name || "One Size" }
  end
  
  # Add tags
  item_data[:tags].each do |tag_name|
    tag = Tag.find_or_create_by!(name: tag_name) { |t| t.tag_type = "category" }
    ItemTag.find_or_create_by!(item_id: item.id, tag_id: tag.id)
  end
  
  puts "  #{status}: #{item_data[:name]}"
  puts "    📸 Cover: #{cover_url}"
  puts "    📸 Additional: #{additional_url} #{'✅ (v2)' if has_v2}#{'⚠️ (using v1)' unless has_v2}"
  puts "    📁 Category: #{category.name} → #{subcategory.name}"
  puts ""
  
  return item
end

# ============================================
# SPORT ITEMS
# ============================================
puts "📊 SPORT ITEMS:"
puts "-" * 40

sport_items = [
  {
    name: "Swim Cap",
    description: "Mountain Ridge High official swim cap. Durable silicone material with school logo.",
    price: 95.00,
    label: "Swimming Cap",
    folder: "sport",
    image_prefix: "swim_cap",
    has_v2: false,
    brand: brands["Speedo"],
    gender: genders["Unisex"],
    size: nil,
    color: colors["Navy"],
    sub_category: sport_subcategories["Swimming"],
    tags: ["swimming", "swim", "uniform"],
    quantity: 25
  },
  {
    name: "Swim Short",
    description: "Mountain Ridge High swimming shorts. Quick-dry material with school logo.",
    price: 180.00,
    label: "Swimming Shorts",
    folder: "sport",
    image_prefix: "swim_short",
    has_v2: false,
    brand: brands["Speedo"],
    gender: genders["Boys"],
    size: sizes["M"],
    color: colors["Black"],
    sub_category: sport_subcategories["Swimming"],
    tags: ["swimming", "swim", "uniform"],
    quantity: 12
  },
  {
    name: "Swimming Costume",
    description: "Mountain Ridge High swimming costume. Professional racing suit with school colors.",
    price: 250.00,
    label: "Swimming Costume",
    folder: "sport",
    image_prefix: "swimming_costume",
    has_v2: true,  # ✅ Has v2
    brand: brands["Speedo"],
    gender: genders["Girls"],
    size: sizes["M"],
    color: colors["Navy"],
    sub_category: sport_subcategories["Swimming"],
    tags: ["swimming", "swim", "uniform"],
    quantity: 10
  },
  {
    name: "Swimming Pants",
    description: "Mountain Ridge High swimming pants. Comfortable and durable for swimming training.",
    price: 210.00,
    label: "Swimming Pants",
    folder: "sport",
    image_prefix: "swimming_pants",
    has_v2: false,
    brand: brands["Speedo"],
    gender: genders["Boys"],
    size: sizes["L"],
    color: colors["Black"],
    sub_category: sport_subcategories["Swimming"],
    tags: ["swimming", "swim", "uniform"],
    quantity: 8
  },
  {
    name: "Cap",
    description: "Mountain Ridge High swimming cap. Lightweight and comfortable for all swimmers.",
    price: 85.00,
    label: "Swimming Cap",
    folder: "sport",
    image_prefix: "cap",
    has_v2: false,
    brand: brands["Speedo"],
    gender: genders["Unisex"],
    size: nil,
    color: colors["Navy"],
    sub_category: sport_subcategories["Swimming"],
    tags: ["swimming", "swim"],
    quantity: 30
  },
  {
    name: "Red & White Jersey",
    description: "Official Mountain Ridge High red and white jersey. Perfect for soccer and rugby.",
    price: 200.00,
    label: "School Sports Jersey",
    folder: "sport",
    image_prefix: "red_white_jersey",
    has_v2: false,
    brand: brands["Adidas"],
    gender: genders["Unisex"],
    size: sizes["L"],
    color: colors["Red"],
    sub_category: sport_subcategories["Soccer"],
    tags: ["soccer", "rugby", "uniform"],
    quantity: 20
  },
  {
    name: "Track Top",
    description: "Mountain Ridge High official track and field top. Lightweight, breathable fabric.",
    price: 250.00,
    label: "Track & Field Uniform",
    folder: "sport",
    image_prefix: "tracktop",
    has_v2: false,
    brand: brands["Nike"],
    gender: genders["Unisex"],
    size: sizes["M"],
    color: colors["Blue"],
    sub_category: sport_subcategories["Athletics"],
    tags: ["track", "uniform"],
    quantity: 15
  },
  {
    name: "Sport Tricot",
    description: "Mountain Ridge High sport tricot. Versatile training top for all sports.",
    price: 230.00,
    label: "Training Tricot",
    folder: "sport",
    image_prefix: "sport_tricot",
    has_v2: false,
    brand: brands["Puma"],
    gender: genders["Unisex"],
    size: sizes["L"],
    color: colors["Blue"],
    sub_category: sport_subcategories["Sportswear"],
    tags: ["training", "sports", "uniform"],
    quantity: 14
  },
  {
    name: "Sun Shirt",
    description: "Mountain Ridge High sun protection shirt. UV-protective fabric for outdoor sports.",
    price: 165.00,
    label: "Sun Protection Shirt",
    folder: "sport",
    image_prefix: "sun_shirt",
    has_v2: false,
    brand: brands["Nike"],
    gender: genders["Unisex"],
    size: sizes["M"],
    color: colors["White"],
    sub_category: sport_subcategories["Sportswear"],
    tags: ["training", "uniform", "sports"],
    quantity: 18
  },
  {
    name: "Blue T-Shirt",
    description: "Mountain Ridge High blue t-shirt. Comfortable cotton blend for everyday wear.",
    price: 120.00,
    label: "School T-Shirt",
    folder: "sport",
    image_prefix: "t_shirt_blue",
    has_v2: false,
    brand: brands["Adidas"],
    gender: genders["Unisex"],
    size: sizes["M"],
    color: colors["Blue"],
    sub_category: sport_subcategories["Sportswear"],
    tags: ["uniform", "training"],
    quantity: 25
  },
  {
    name: "Red T-Shirt",
    description: "Mountain Ridge High red t-shirt. Perfect for sports events and school activities.",
    price: 120.00,
    label: "School T-Shirt",
    folder: "sport",
    image_prefix: "t_shirt_red",
    has_v2: false,
    brand: brands["Adidas"],
    gender: genders["Unisex"],
    size: sizes["M"],
    color: colors["Red"],
    sub_category: sport_subcategories["Sportswear"],
    tags: ["uniform", "training"],
    quantity: 25
  }
]

sport_items.each do |item_data|
  create_item_with_images(item_data, school, shop, CDN_BASE, sport_category, item_data[:sub_category])
end

# ============================================
# UNIFORM ITEMS
# ============================================
puts "📊 UNIFORM ITEMS:"
puts "-" * 40

uniform_items = [
  {
    name: "Fleece Jacket",
    description: "Mountain Ridge High fleece jacket. Warm and comfortable for cold weather.",
    price: 350.00,
    label: "School Fleece Jacket",
    folder: "uniform",
    image_prefix: "Fleece_Jacket",
    has_v2: false,
    brand: brands["Adidas"],
    gender: genders["Unisex"],
    size: sizes["L"],
    color: colors["Navy"],
    sub_category: uniform_subcategories["Jackets & Hoodies"],
    tags: ["jacket", "uniform", "winter"],
    quantity: 20
  },
  {
    name: "Kangaroo Hoodie",
    description: "Mountain Ridge High kangaroo hoodie. Stylish and comfortable with front pocket.",
    price: 280.00,
    label: "School Hoodie",
    folder: "uniform",
    image_prefix: "kangaroo_hoodie",
    has_v2: false,
    brand: brands["Nike"],
    gender: genders["Unisex"],
    size: sizes["M"],
    color: colors["Blue"],
    sub_category: uniform_subcategories["Jackets & Hoodies"],
    tags: ["hoodie", "uniform", "winter"],
    quantity: 25
  },
  {
    name: "Golf Shirt",
    description: "Mountain Ridge High golf shirt. Breathable, moisture-wicking fabric.",
    price: 220.00,
    label: "School Golf Shirt",
    folder: "uniform",
    image_prefix: "golf_shirt_v1",
    has_v2: false,
    brand: brands["Puma"],
    gender: genders["Unisex"],
    size: sizes["M"],
    color: colors["White"],
    sub_category: uniform_subcategories["Shirts & Golfers"],
    tags: ["golf", "uniform"],
    quantity: 30
  },
  {
    name: "Jersey",
    description: "Mountain Ridge High official jersey. High-quality material with school colors.",
    price: 250.00,
    label: "School Jersey",
    folder: "uniform",
    image_prefix: "jersey_v1",
    has_v2: false,
    brand: brands["Adidas"],
    gender: genders["Unisex"],
    size: sizes["L"],
    color: colors["Red"],
    sub_category: uniform_subcategories["Shirts & Golfers"],
    tags: ["jersey", "uniform"],
    quantity: 25
  },
  {
    name: "Pleated Skirt",
    description: "Mountain Ridge High pleated skirt. Classic school design with comfortable fit.",
    price: 180.00,
    label: "School Pleated Skirt",
    folder: "uniform",
    image_prefix: "pleaded_skirt",
    has_v2: false,
    brand: nil,
    gender: genders["Girls"],
    size: sizes["M"],
    color: colors["Navy"],
    sub_category: uniform_subcategories["Skirts & Dresses"],
    tags: ["skirt", "uniform"],
    quantity: 15
  },
  {
    name: "Skirt",
    description: "Mountain Ridge High school skirt. Simple, elegant design for daily school wear.",
    price: 160.00,
    label: "School Skirt",
    folder: "uniform",
    image_prefix: "skirt",
    has_v2: false,
    brand: nil,
    gender: genders["Girls"],
    size: sizes["M"],
    color: colors["Black"],
    sub_category: uniform_subcategories["Skirts & Dresses"],
    tags: ["skirt", "uniform"],
    quantity: 20
  },
  {
    name: "Arena Visor Cap",
    description: "Mountain Ridge High arena visor cap. Perfect for outdoor sports and sun protection.",
    price: 120.00,
    label: "Visor Cap",
    folder: "uniform",
    image_prefix: "arena_visor_cap",
    has_v2: false,
    brand: brands["Arena"],
    gender: genders["Unisex"],
    size: nil,
    color: colors["White"],
    sub_category: uniform_subcategories["Accessories"],
    tags: ["cap", "uniform"],
    quantity: 35
  },
  {
    name: "Durafast Swim Cap",
    description: "Mountain Ridge High Durafast swim cap. Durable silicone material for swimming.",
    price: 95.00,
    label: "Swim Cap",
    folder: "uniform",
    image_prefix: "durafast_swim_cap",
    has_v2: false,
    brand: brands["Speedo"],
    gender: genders["Unisex"],
    size: nil,
    color: colors["Navy"],
    sub_category: uniform_subcategories["Accessories"],
    tags: ["swimming", "cap", "uniform"],
    quantity: 30
  },
  {
    name: "Embroidered Badge",
    description: "Mountain Ridge High embroidered badge. High-quality school crest for blazers.",
    price: 45.00,
    label: "School Badge",
    folder: "uniform",
    image_prefix: "emboided_bap",
    has_v2: false,
    brand: nil,
    gender: genders["Unisex"],
    size: nil,
    color: colors["Navy"],
    sub_category: uniform_subcategories["Accessories"],
    tags: ["uniform"],
    quantity: 50
  }
]

uniform_items.each do |item_data|
  create_item_with_images(item_data, school, shop, CDN_BASE, uniforms_category, item_data[:sub_category])
end

# ============================================
# ACCESSORY ITEMS
# ============================================
puts "📊 ACCESSORY ITEMS:"
puts "-" * 40

accessory_items = [
  {
    name: "Beanie",
    description: "Mountain Ridge High beanie. Warm and comfortable for cold weather.",
    price: 85.00,
    label: "School Beanie",
    folder: "accessories",
    image_prefix: "beane",
    has_v2: false,
    brand: nil,
    gender: genders["Unisex"],
    size: sizes["One Size"],
    color: colors["Navy"],
    sub_category: accessory_subcategories["Scarves & Beanies"],
    tags: ["beanie", "winter", "uniform"],
    quantity: 40
  },
  {
    name: "Scarf",
    description: "Mountain Ridge High scarf. Soft and warm, perfect for winter.",
    price: 95.00,
    label: "School Scarf",
    folder: "accessories",
    image_prefix: "scarf",
    has_v2: false,
    brand: nil,
    gender: genders["Unisex"],
    size: sizes["One Size"],
    color: colors["Navy"],
    sub_category: accessory_subcategories["Scarves & Beanies"],
    tags: ["scarf", "winter", "uniform"],
    quantity: 35
  },
  {
    name: "Shopping Bag",
    description: "Mountain Ridge High shopping bag. Reusable and eco-friendly with school logo.",
    price: 45.00,
    label: "School Shopping Bag",
    folder: "accessories",
    image_prefix: "shopping_bag",
    has_v2: false,
    brand: nil,
    gender: genders["Unisex"],
    size: nil,
    color: colors["White"],
    sub_category: accessory_subcategories["Bags"],
    tags: ["bag", "school"],
    quantity: 50
  },
  {
    name: "Sport Bag",
    description: "Mountain Ridge High sport bag. Durable and spacious for sports equipment.",
    price: 180.00,
    label: "School Sport Bag",
    folder: "accessories",
    image_prefix: "sport_bag",
    has_v2: false,
    brand: brands["Nike"],
    gender: genders["Unisex"],
    size: nil,
    color: colors["Black"],
    sub_category: accessory_subcategories["Bags"],
    tags: ["bag", "school"],
    quantity: 25
  }
]

accessory_items.each do |item_data|
  create_item_with_images(item_data, school, shop, CDN_BASE, accessories_category, item_data[:sub_category])
end

# ============================================
# FINAL SUMMARY
# ============================================
puts "=" * 60
puts "✅ MOUNTAIN RIDGE HIGH COMPLETE SEEDING COMPLETE!"
puts "=" * 60
puts ""
puts "📊 Final Summary:"
puts "  🏫 School: #{school.name} (ID: #{school.id})"
puts "  📍 Province: #{school.province&.name || 'N/A'}"
puts "  👤 User: #{user.email} (ID: #{user.id})"
puts "  🏪 Shop: #{shop.name} (ID: #{shop.id})"
puts ""
puts "📂 Category Breakdown:"
puts "  📁 Sport:"
sport_subcategories.each do |name, sub|
  count = Item.where(school_id: school.id, sub_category_id: sub.id).count
  puts "    ├── #{name}: #{count} items"
end
puts "  📁 Uniforms:"
uniform_subcategories.each do |name, sub|
  count = Item.where(school_id: school.id, sub_category_id: sub.id).count
  puts "    ├── #{name}: #{count} items"
end
puts "  📁 Accessories:"
accessory_subcategories.each do |name, sub|
  count = Item.where(school_id: school.id, sub_category_id: sub.id).count
  puts "    ├── #{name}: #{count} items"
end
puts ""
puts "📸 Total Items: #{Item.where(school_id: school.id).count}"
puts ""
puts "🏷️ Items with v2 images:"
items_with_v2 = Item.where(school_id: school.id).where("additional_photo LIKE '%_v2.%'")
if items_with_v2.any?
  items_with_v2.each do |item|
    puts "  - #{item.name}"
  end
else
  puts "  None (only 1 item has v2: Swimming Costume)"
end
puts ""
puts "=" * 60