# db/seeds_mountain_ridge_uniform.rb
puts "👔 Starting Mountain Ridge High Uniform Items Seeding..."
puts "=" * 60

CDN_BASE = "https://cdn.skoolswap.co.za"
SCHOOL_NAME = "Mountain Ridge High"

# ============================================
# 1. FIND OR CREATE SCHOOL
# ============================================
puts "1. Setting up school and shop..."

school = School.find_by(name: SCHOOL_NAME)
if school.nil?
  puts "❌ Error: School '#{SCHOOL_NAME}' not found!"
  puts "   Please run the sport seed first or create the school."
  exit
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
  s.name = "#{SCHOOL_NAME} Uniform Shop"
  s.description = "Official uniform shop for #{SCHOOL_NAME}"
  s.display_name = "#{SCHOOL_NAME} Uniform Shop"
  s.location = "Cape Town"
end
puts "✅ Shop: #{shop.name} (ID: #{shop.id})"

# ============================================
# 2. ENSURE CATEGORIES EXIST
# ============================================
puts "2. Ensuring categories exist..."

# Main Category: Uniforms
uniforms_category = MainCategory.find_or_create_by!(name: "Uniforms") do |mc|
  mc.description = "School uniforms and apparel"
  mc.icon_name = "school"
  mc.is_active = true
  mc.display_order = 2
end
puts "✅ Main Category: #{uniforms_category.name}"

# Sub Categories under Uniforms
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

puts "✅ Sub Categories: #{uniform_subcategories.keys.join(', ')}"

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
# 4. CREATE UNIFORM ITEMS
# ============================================
puts "4. Creating uniform items..."
puts ""

# Define all uniform items
uniform_items = [
  # JACKETS & HOODIES
  {
    name: "Fleece Jacket",
    description: "Mountain Ridge High fleece jacket. Warm and comfortable for cold weather. Features school logo and colors.",
    price: 350.00,
    label: "School Fleece Jacket",
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
    description: "Mountain Ridge High kangaroo hoodie. Stylish and comfortable with front pocket and school logo.",
    price: 280.00,
    label: "School Hoodie",
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
    name: "Zip Hoodie",
    description: "Mountain Ridge High zip hoodie. Stylish zip-up hoodie with school logo. Perfect for cooler days.",
    price: 320.00,
    label: "School Zip Hoodie",
    image_prefix: "zip_hoodie",
    has_v2: true,  # ✅ Has v2
    brand: brands["Nike"],
    gender: genders["Unisex"],
    size: sizes["M"],
    color: colors["Navy"],
    sub_category: uniform_subcategories["Jackets & Hoodies"],
    tags: ["hoodie", "uniform", "winter"],
    quantity: 20
  },
  
  # SHIRTS & GOLFERS
  {
    name: "Golf Shirt",
    description: "Mountain Ridge High golf shirt. Breathable, moisture-wicking fabric perfect for golf and outdoor activities.",
    price: 220.00,
    label: "School Golf Shirt",
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
    description: "Mountain Ridge High official jersey. High-quality material with school colors and logo. Perfect for sports events.",
    price: 250.00,
    label: "School Jersey",
    image_prefix: "jersey_v1",
    has_v2: true,  # ✅ Has v2
    brand: brands["Adidas"],
    gender: genders["Unisex"],
    size: sizes["L"],
    color: colors["Red"],
    sub_category: uniform_subcategories["Shirts & Golfers"],
    tags: ["jersey", "uniform"],
    quantity: 25
  },
  
  # SKIRTS & DRESSES
  {
    name: "Pleated Skirt",
    description: "Mountain Ridge High pleated skirt. Classic school design with comfortable fit and school colors.",
    price: 180.00,
    label: "School Pleated Skirt",
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
    description: "Mountain Ridge High school skirt. Simple, elegant design perfect for daily school wear.",
    price: 160.00,
    label: "School Skirt",
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
  
  # ACCESSORIES
  {
    name: "Arena Visor Cap",
    description: "Mountain Ridge High arena visor cap. Perfect for outdoor sports and sun protection.",
    price: 120.00,
    label: "Visor Cap",
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
    description: "Mountain Ridge High Durafast swim cap. Durable silicone material for swimming and water sports.",
    price: 95.00,
    label: "Swim Cap",
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
    description: "Mountain Ridge High embroidered badge. High-quality school crest for blazers and jackets.",
    price: 45.00,
    label: "School Badge",
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

# Create items
created_count = 0
updated_count = 0

uniform_items.each do |item_data|
  folder = "uniform"
  image_prefix = item_data[:image_prefix]
  
  # Build URLs - handle special cases
  if image_prefix == "golf_shirt_v1"
    cover_url = "#{CDN_BASE}/schools_demo/mountain-ridge-high/#{folder}/golf_shirt_v1.webp.png"
  elsif image_prefix == "Fleece_Jacket"
    cover_url = "#{CDN_BASE}/schools_demo/mountain-ridge-high/#{folder}/Fleece_Jacket_v1.webp"
  else
    cover_url = "#{CDN_BASE}/schools_demo/mountain-ridge-high/#{folder}/#{image_prefix}_v1.webp"
  end
  
  # Check if v2 exists
  has_v2 = item_data[:has_v2]
  
  if has_v2
    # For jersey, use jersey_v2.webp (not jersey_v1_v2)
    if image_prefix == "jersey_v1"
      additional_url = "#{CDN_BASE}/schools_demo/mountain-ridge-high/#{folder}/jersey_v2.webp"
    else
      additional_url = "#{CDN_BASE}/schools_demo/mountain-ridge-high/#{folder}/#{image_prefix}_v2.webp"
    end
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
      main_category_id: uniforms_category.id,
      sub_category_id: item_data[:sub_category].id,
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
    updated_count += 1
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
      main_category_id: uniforms_category.id,
      sub_category_id: item_data[:sub_category].id,
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
    created_count += 1
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
  puts "    📸 Additional: #{additional_url} #{'✅ (has v2)' if has_v2}#{'⚠️ (using v1, no v2)' unless has_v2}"
  puts "    📁 Category: #{uniforms_category.name} → #{item_data[:sub_category].name}"
  puts "    🏷️ Tags: #{item_data[:tags].join(', ')}"
  puts ""
end

# ============================================
# FINAL SUMMARY
# ============================================
puts "=" * 60
puts "✅ MOUNTAIN RIDGE HIGH UNIFORM SEEDING COMPLETE!"
puts "=" * 60
puts ""
puts "📊 Summary:"
puts "  🏫 School: #{school.name} (ID: #{school.id})"
puts "  📍 Province: #{school.province&.name || 'N/A'}"
puts "  👤 User: #{user.email} (ID: #{user.id})"
puts "  🏪 Shop: #{shop.name} (ID: #{shop.id})"
puts "  📦 Items Created: #{created_count}"
puts "  🔄 Items Updated: #{updated_count}"
puts "  📚 Total Items: #{uniform_items.count}"
puts ""
puts "📂 Category Breakdown:"
uniform_subcategories.each do |name, sub|
  count = Item.where(school_id: school.id, sub_category_id: sub.id).count
  puts "  📁 #{name}: #{count} items"
end
puts ""
puts "📸 Image Status:"
uniform_items.each do |item|
  v2_status = item[:has_v2] ? "✅ Has v2" : "⚠️ No v2 (using v1)"
  puts "  - #{item[:name]}: #{v2_status}"
end
puts ""
puts "📸 Images Location:"
puts "  #{CDN_BASE}/schools_demo/mountain-ridge-high/uniform/"
puts ""
puts "=" * 60