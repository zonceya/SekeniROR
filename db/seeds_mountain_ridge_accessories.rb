# db/seeds_mountain_ridge_accessories.rb
puts "🎒 Starting Mountain Ridge High Accessories Seeding..."

CDN_BASE = "https://cdn.skoolswap.co.za"
SCHOOL_NAME = "Mountain Ridge High"

# ============================================
# 1. FIND EXISTING SCHOOL
# ============================================
puts "1. Finding school..."

school = School.find_by(name: SCHOOL_NAME)
if school.nil?
  puts "❌ Error: School '#{SCHOOL_NAME}' not found!"
  puts "   Please run the sport seed first or create the school."
  exit
end
puts "✅ Found school: #{school.name} (ID: #{school.id})"

# ============================================
# 2. FIND OR CREATE SHOP FOR THE SCHOOL
# ============================================
puts "2. Finding or creating shop..."

# Since school is a user, find the user associated with this school
school_email = "mountainridge@example.com"
user = User.find_by(email: school_email)

if user.nil?
  puts "  Creating user for school shop..."
  user = User.create!(
    name: SCHOOL_NAME,
    email: school_email,
    password_digest: BCrypt::Password.create("password123"),
    role: "user",
    status: true,
    auth_mode: "default_auth_mode"
  )
  puts "  ✅ Created user: #{user.email} (ID: #{user.id})"
else
  puts "  ✅ Found user: #{user.email} (ID: #{user.id})"
end

# Find or create shop for this user
shop = Shop.find_by(user_id: user.id)

if shop.nil?
  puts "  Creating shop for user..."
  shop = Shop.create!(
    user_id: user.id,
    name: "#{SCHOOL_NAME} Shop",
    description: "Official shop for #{SCHOOL_NAME}",
    display_name: "#{SCHOOL_NAME} Shop",
    location: "Cape Town"
  )
  puts "  ✅ Created shop: #{shop.name} (ID: #{shop.id})"
else
  puts "  ✅ Found shop: #{shop.name} (ID: #{shop.id})"
end

# ============================================
# 3. USE EXISTING CATEGORIES
# ============================================
puts "3. Using existing categories..."

# Find the Accessories main category
accessories_category = MainCategory.find_by(name: "Accessories")
if accessories_category.nil?
  puts "❌ Error: 'Accessories' main category not found!"
  puts "   Please run the main seed first."
  exit
end
puts "✅ Found main category: #{accessories_category.name}"

# Find or create sub-categories under Accessories
accessories_subcategories = {}

# Check existing sub-categories under Accessories
SubCategory.where(main_category_id: accessories_category.id).each do |sc|
  accessories_subcategories[sc.name] = sc
end

puts "  📋 Existing sub-categories under Accessories:"
accessories_subcategories.keys.each { |name| puts "    - #{name}" }

# Create missing sub-categories we need
needed_subcategories = ["Bags", "Hats", "Scarves & Beanies", "School Bags", "Accessories"]

needed_subcategories.each do |sub_name|
  unless accessories_subcategories[sub_name]
    puts "  ⚠️ Creating '#{sub_name}' sub-category..."
    accessories_subcategories[sub_name] = SubCategory.create!(
      name: sub_name,
      main_category_id: accessories_category.id,
      description: "#{sub_name} for school accessories",
      is_active: true,
      display_order: accessories_subcategories.keys.count + 1
    )
  end
end

# Map items to sub-categories
bags_sub = accessories_subcategories["Bags"] || accessories_subcategories["School Bags"]
hats_sub = accessories_subcategories["Hats"]
scarves_sub = accessories_subcategories["Scarves & Beanies"]
accessories_sub = accessories_subcategories["Accessories"]

# ============================================
# 4. CREATE BRANDS
# ============================================
puts "4. Creating brands..."

nike = Brand.find_or_create_by!(name: "Nike")
adidas = Brand.find_or_create_by!(name: "Adidas")
puma = Brand.find_or_create_by!(name: "Puma")
speedo = Brand.find_or_create_by!(name: "Speedo")
arena = Brand.find_or_create_by!(name: "Arena")

# ============================================
# 5. CREATE ITEM CONDITIONS
# ============================================
puts "5. Creating item conditions..."

new_condition = ItemCondition.find_or_create_by!(name: "New") do |ic|
  ic.description = "Brand new item"
end

# ============================================
# 6. CREATE SIZES & COLORS
# ============================================
puts "6. Creating sizes and colors..."

sizes = {
  "S" => ItemSize.find_or_create_by!(name: "S"),
  "M" => ItemSize.find_or_create_by!(name: "M"),
  "L" => ItemSize.find_or_create_by!(name: "L"),
  "XL" => ItemSize.find_or_create_by!(name: "XL"),
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

# ============================================
# 7. CREATE GENDERS
# ============================================
puts "7. Creating genders..."

boys = Gender.find_or_create_by!(name: "Boys") do |g|
  g.category = "standard"
  g.display_name = "Boys"
  g.gender_group = "male"
end

girls = Gender.find_or_create_by!(name: "Girls") do |g|
  g.category = "standard"
  g.display_name = "Girls"
  g.gender_group = "female"
end

unisex = Gender.find_or_create_by!(name: "Unisex") do |g|
  g.category = "standard"
  g.display_name = "Unisex"
  g.gender_group = "unisex"
end

# ============================================
# 8. CREATE TAGS
# ============================================
puts "8. Creating tags..."

accessory_tags = {
  "accessory" => Tag.find_or_create_by!(name: "accessory") { |t| t.tag_type = "category" },
  "school" => Tag.find_or_create_by!(name: "school") { |t| t.tag_type = "category" },
  "bag" => Tag.find_or_create_by!(name: "bag") { |t| t.tag_type = "accessory" },
  "sport bag" => Tag.find_or_create_by!(name: "sport bag") { |t| t.tag_type = "accessory" },
  "shopping bag" => Tag.find_or_create_by!(name: "shopping bag") { |t| t.tag_type = "accessory" },
  "beanie" => Tag.find_or_create_by!(name: "beanie") { |t| t.tag_type = "accessory" },
  "scarf" => Tag.find_or_create_by!(name: "scarf") { |t| t.tag_type = "accessory" },
  "winter" => Tag.find_or_create_by!(name: "winter") { |t| t.tag_type = "season" },
  "uniform" => Tag.find_or_create_by!(name: "uniform") { |t| t.tag_type = "category" }
}

# ============================================
# 9. CREATE ACCESSORY ITEMS WITH IMAGES
# ============================================
puts "9. Creating Mountain Ridge High accessory items..."
puts ""

# Define all accessory items
accessory_items = [
  {
    name: "Beanie",
    description: "Mountain Ridge High beanie. Warm and comfortable for cold weather. Features school colors and logo.",
    price: 85.00,
    label: "School Beanie",
    image_prefix: "beane",
    has_v2: false,
    brand: nil,
    gender: unisex,
    size: sizes["One Size"],
    color: colors["Navy"],
    sub_category: scarves_sub || accessories_sub,
    tags: ["beanie", "winter", "uniform"],
    quantity: 40
  },
  {
    name: "Scarf",
    description: "Mountain Ridge High scarf. Soft and warm, perfect for winter. Features school colors and logo.",
    price: 95.00,
    label: "School Scarf",
    image_prefix: "scarf",
    has_v2: false,
    brand: nil,
    gender: unisex,
    size: sizes["One Size"],
    color: colors["Navy"],
    sub_category: scarves_sub || accessories_sub,
    tags: ["scarf", "winter", "uniform"],
    quantity: 35
  },
  {
    name: "Shopping Bag",
    description: "Mountain Ridge High shopping bag. Reusable and eco-friendly with school logo.",
    price: 45.00,
    label: "School Shopping Bag",
    image_prefix: "shopping_bag",
    has_v2: false,
    brand: nil,
    gender: unisex,
    size: nil,
    color: colors["White"],
    sub_category: bags_sub || accessories_sub,
    tags: ["shopping bag", "bag", "school"],
    quantity: 50
  },
  {
    name: "Sport Bag",
    description: "Mountain Ridge High sport bag. Durable and spacious, perfect for sports equipment and gym clothes.",
    price: 180.00,
    label: "School Sport Bag",
    image_prefix: "sport_bag",
    has_v2: false,
    brand: nike,
    gender: unisex,
    size: nil,
    color: colors["Black"],
    sub_category: bags_sub || accessories_sub,
    tags: ["sport bag", "bag", "school"],
    quantity: 25
  }
]

# Create the items
created_count = 0
updated_count = 0

accessory_items.each do |item_data|
  # Build image URLs
  image_prefix = item_data[:image_prefix]
  
  # Handle special cases
  if image_prefix == "beane"
    cover_url = "#{CDN_BASE}/schools_demo/mountain-ridge-high/accessories/beane_v1.webp"
  elsif image_prefix == "scarf"
    cover_url = "#{CDN_BASE}/schools_demo/mountain-ridge-high/accessories/scarf_v1.webp"
  elsif image_prefix == "shopping_bag"
    cover_url = "#{CDN_BASE}/schools_demo/mountain-ridge-high/accessories/shopping_bag_v1.webp"
  elsif image_prefix == "sport_bag"
    cover_url = "#{CDN_BASE}/schools_demo/mountain-ridge-high/accessories/sport_bag_v1.webp"
  else
    cover_url = "#{CDN_BASE}/schools_demo/mountain-ridge-high/accessories/#{image_prefix}_v1.webp"
  end
  
  # Use cover as additional if no v2
  additional_url = cover_url

  # Find or create the item
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
      main_category_id: accessories_category.id,
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
    puts "  🔄 Updated: #{item_data[:name]}"
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
      main_category_id: accessories_category.id,
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
    puts "  ✅ Created: #{item_data[:name]}"
  end

  # Create item variant
  variant_attributes = {
    item_id: item.id,
    condition_id: new_condition.id
  }
  
  variant_attributes[:size_id] = item_data[:size]&.id if item_data[:size].present?
  variant_attributes[:color_id] = item_data[:color]&.id if item_data[:color].present?
  
  variant = ItemVariant.find_or_create_by!(variant_attributes) do |v|
    v.price = item_data[:price]
    v.quantity = item_data[:quantity]
    v.reserved = 0
    v.is_active = true
    v.sku = "#{item_data[:image_prefix].upcase}-#{SecureRandom.hex(4)}".upcase
    v.metadata = { 
      color: item_data[:color]&.name || "N/A", 
      size: item_data[:size]&.name || "One Size" 
    }
  end

  # Add tags
  item_data[:tags].each do |tag_name|
    tag = accessory_tags[tag_name] || Tag.find_or_create_by!(name: tag_name) { |t| t.tag_type = "accessory" }
    ItemTag.find_or_create_by!(item_id: item.id, tag_id: tag.id)
  end

  puts "    📸 Cover: #{cover_url}"
  puts "    🏷️ Tags: #{item_data[:tags].join(', ')}"
  puts "    📁 Category: #{accessories_category.name} → #{item_data[:sub_category].name}"
  puts ""
end

# ============================================
# FINAL SUMMARY
# ============================================
puts "=" * 60
puts "✅ MOUNTAIN RIDGE HIGH ACCESSORIES SEEDING COMPLETE!"
puts "=" * 60
puts ""
puts "📊 Summary:"
puts "  🏫 School: #{school.name} (ID: #{school.id})"
puts "  📍 Province: #{school.province&.name || 'N/A'}"
puts "  👤 User: #{user.email} (ID: #{user.id})"
puts "  🏪 Shop: #{shop.name} (ID: #{shop.id})"
puts "  📦 Items Created: #{created_count}"
puts "  🔄 Items Updated: #{updated_count}"
puts "  📚 Total Items: #{accessory_items.count}"
puts ""
puts "📂 Category Structure:"
puts "  📁 #{accessories_category.name} (Main Category)"
sub_counts = accessory_items.group_by { |i| i[:sub_category].name }
sub_counts.each do |name, items|
  puts "    ├── #{name} - #{items.count} items"
end
puts ""
puts "📸 Images Location:"
puts "  #{CDN_BASE}/schools_demo/mountain-ridge-high/accessories/"
puts ""
puts "🏷️ Tags Created:"
accessory_tags.keys.each { |tag| puts "  - #{tag}" }
puts ""
puts "=" * 60