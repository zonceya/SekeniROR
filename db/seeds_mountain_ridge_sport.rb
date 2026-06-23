# db/seeds_mountain_ridge_sport.rb
puts "⚽ Starting Mountain Ridge High Sport Items Seeding..."
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
  puts "   Please run the main seed first or create the school."
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
  s.name = "#{SCHOOL_NAME} Sport Shop"
  s.description = "Official sport shop for #{SCHOOL_NAME}"
  s.display_name = "#{SCHOOL_NAME} Sport Shop"
  s.location = "Cape Town"
end
puts "✅ Shop: #{shop.name} (ID: #{shop.id})"

# ============================================
# 2. ENSURE CATEGORIES EXIST
# ============================================
puts "2. Ensuring categories exist..."

# Main Category: Sport
sport_category = MainCategory.find_or_create_by!(name: "Sport") do |mc|
  mc.description = "Sports equipment and uniforms"
  mc.icon_name = "sports"
  mc.is_active = true
  mc.display_order = 1
end
puts "✅ Main Category: #{sport_category.name}"

# Sub Categories under Sport
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

puts "✅ Sub Categories: #{sport_subcategories.keys.join(', ')}"

# ============================================
# 3. CREATE BRANDS, SIZES, COLORS, GENDERS, CONDITIONS
# ============================================
puts "3. Creating brands, sizes, colors, genders, conditions..."

brands = {
  "Nike" => Brand.find_or_create_by!(name: "Nike"),
  "Adidas" => Brand.find_or_create_by!(name: "Adidas"),
  "Puma" => Brand.find_or_create_by!(name: "Puma"),
  "Speedo" => Brand.find_or_create_by!(name: "Speedo")
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
# 4. CREATE SPORT ITEMS
# ============================================
puts "4. Creating sport items..."
puts ""

# Define all sport items
sport_items = [
  {
    name: "Swim Cap",
    description: "Mountain Ridge High official swim cap. Durable silicone material with school logo. Perfect for swimming competitions and training.",
    price: 95.00,
    label: "Swimming Cap",
    image_prefix: "swim_cap",
    has_v2: false,  # ❌ No v2
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
    description: "Mountain Ridge High swimming shorts. Quick-dry material with school logo. Ideal for swimming lessons and water sports.",
    price: 180.00,
    label: "Swimming Shorts",
    image_prefix: "swim_short",
    has_v2: false,  # ❌ No v2
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
    description: "Mountain Ridge High swimming costume. Professional racing suit with school colors. Perfect for competitive swimming.",
    price: 250.00,
    label: "Swimming Costume",
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
    description: "Mountain Ridge High swimming pants. Comfortable and durable for swimming training and competitions.",
    price: 210.00,
    label: "Swimming Pants",
    image_prefix: "swimming_pants",
    has_v2: false,  # ❌ No v2
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
    image_prefix: "cap",
    has_v2: false,  # ❌ No v2
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
    description: "Official Mountain Ridge High red and white jersey. Made with high-quality materials for comfort during matches. Perfect for soccer and rugby.",
    price: 200.00,
    label: "School Sports Jersey",
    image_prefix: "red_white_jersey",
    has_v2: false,  # ❌ No v2
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
    description: "Mountain Ridge High official track and field top. Lightweight, breathable fabric perfect for athletics. Features school colors and logo.",
    price: 250.00,
    label: "Track & Field Uniform",
    image_prefix: "tracktop",
    has_v2: true,  # ✅ Has v2
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
    description: "Mountain Ridge High sport tricot. Versatile training top for all sports activities.",
    price: 230.00,
    label: "Training Tricot",
    image_prefix: "sport_tricot",
    has_v2: false,  # ❌ No v2
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
    description: "Mountain Ridge High sun protection shirt. UV-protective fabric perfect for outdoor sports and training.",
    price: 165.00,
    label: "Sun Protection Shirt",
    image_prefix: "sun_shirt",
    has_v2: false,  # ❌ No v2
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
    description: "Mountain Ridge High blue t-shirt. Comfortable cotton blend for everyday wear and sports activities.",
    price: 120.00,
    label: "School T-Shirt",
    image_prefix: "t_shirt_blue",
    has_v2: false,  # ❌ No v2
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
    image_prefix: "t_shirt_red",
    has_v2: false,  # ❌ No v2
    brand: brands["Adidas"],
    gender: genders["Unisex"],
    size: sizes["M"],
    color: colors["Red"],
    sub_category: sport_subcategories["Sportswear"],
    tags: ["uniform", "training"],
    quantity: 25
  }
]

# Create items
created_count = 0
updated_count = 0

sport_items.each do |item_data|
  folder = "sport"
  image_prefix = item_data[:image_prefix]
  
  # Build URLs
  cover_url = "#{CDN_BASE}/schools_demo/mountain-ridge-high/#{folder}/#{image_prefix}_v1.webp"
  
  # Check if v2 exists
  has_v2 = item_data[:has_v2]
  
  if has_v2
    additional_url = "#{CDN_BASE}/schools_demo/mountain-ridge-high/#{folder}/#{image_prefix}_v2.webp"
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
      main_category_id: sport_category.id,
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
      main_category_id: sport_category.id,
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
  puts "    📁 Category: #{sport_category.name} → #{item_data[:sub_category].name}"
  puts "    🏷️ Tags: #{item_data[:tags].join(', ')}"
  puts ""
end

# ============================================
# FINAL SUMMARY
# ============================================
puts "=" * 60
puts "✅ MOUNTAIN RIDGE HIGH SPORT SEEDING COMPLETE!"
puts "=" * 60
puts ""
puts "📊 Summary:"
puts "  🏫 School: #{school.name} (ID: #{school.id})"
puts "  📍 Province: #{school.province&.name || 'N/A'}"
puts "  👤 User: #{user.email} (ID: #{user.id})"
puts "  🏪 Shop: #{shop.name} (ID: #{shop.id})"
puts "  📦 Items Created: #{created_count}"
puts "  🔄 Items Updated: #{updated_count}"
puts "  📚 Total Sport Items: #{sport_items.count}"
puts ""
puts "📂 Category Breakdown:"
sport_subcategories.each do |name, sub|
  count = Item.where(school_id: school.id, sub_category_id: sub.id).count
  puts "  📁 #{name}: #{count} items"
end
puts ""
puts "📸 Image Status:"
sport_items.each do |item|
  v2_status = item[:has_v2] ? "✅ Has v2" : "⚠️ No v2 (using v1)"
  puts "  - #{item[:name]}: #{v2_status}"
end
puts ""
puts "📸 Items with v2 images:"
sport_items.select { |i| i[:has_v2] }.each do |item|
  puts "  - #{item[:name]}: #{CDN_BASE}/schools_demo/mountain-ridge-high/sport/#{item[:image_prefix]}_v2.webp"
end
puts ""
puts "📸 Images Location:"
puts "  #{CDN_BASE}/schools_demo/mountain-ridge-high/sport/"
puts ""
puts "=" * 60