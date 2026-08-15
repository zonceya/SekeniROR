# db/seeds_stationery_additions_fixed.rb
puts "📚 Starting Stationery Items Seeding..."
puts "=" * 60

CDN_BASE = "https://cdn.skoolswap.co.za"

# ============================================
# 1. FIND SCHOOLS
# ============================================
puts "1. Finding schools..."

# Check if Riverside College exists, if not create it
mountain_ridge = School.find_by(name: "Mountain Ridge High")
riverside = School.find_by(name: "Riverside College")

if riverside.nil?
  puts "⚠️ Riverside College not found. Creating it..."
  
  province = Province.find_by(name: "Western Cape")
  if province.nil?
    province = Province.create!(name: "Western Cape")
  end
  
  cape_town = Town.find_or_create_by!(name: "Cape Town", province_id: province.id)
  
  location = Location.find_or_create_by!(
    province: "Western Cape",
    town: cape_town
  ) do |l|
    l.country = "South Africa"
    l.state_or_region = "Western Cape"
  end
  
  riverside = School.create!(
    name: "Riverside College",
    location_id: location.id,
    province_id: province.id,
    school_type: "High School"
  )
  puts "✅ Created Riverside College (ID: #{riverside.id})"
  
  # Create shop and user for Riverside
  shop_user = User.find_or_create_by!(email: "riversidecollege@example.com") do |u|
    u.name = "Riverside College Shop"
    u.password_digest = BCrypt::Password.create("password123")
    u.role = "user"
    u.status = true
    u.auth_mode = "default_auth_mode"
  end
  
  Shop.find_or_create_by!(user_id: shop_user.id) do |s|
    s.name = "Riverside College Shop"
    s.description = "Official shop for Riverside College"
    s.location = "Cape Town"
    s.display_name = "Riverside College Shop"
  end
  puts "✅ Created Riverside shop"
end

puts "✅ Mountain Ridge High (ID: #{mountain_ridge.id})"
puts "✅ Riverside College (ID: #{riverside.id})"

# ============================================
# 2. FIND SHOPS
# ============================================
puts "2. Finding shops..."

mr_user = User.find_by(email: "mountainridge@example.com")
mr_shop = Shop.find_by(user_id: mr_user.id) if mr_user

rc_user = User.find_by(email: "riversidecollege@example.com")
rc_shop = Shop.find_by(user_id: rc_user.id) if rc_user

puts "✅ Mountain Ridge Shop: #{mr_shop&.name || 'NOT FOUND'}"
puts "✅ Riverside Shop: #{rc_shop&.name || 'NOT FOUND'}"

# ============================================
# 3. GET CATEGORIES
# ============================================
puts "3. Getting categories..."

stationery_cat = MainCategory.find_by(name: "Stationery")
if stationery_cat.nil?
  puts "❌ Stationery category not found! Creating it..."
  stationery_cat = MainCategory.create!(
    name: "Stationery",
    description: "School stationery and supplies",
    icon_name: "edit",
    is_active: true,
    display_order: 5
  )
end

# Find or create stationery sub-category
stationery_sub = SubCategory.find_or_create_by!(
  name: "Stationery",
  main_category_id: stationery_cat.id
) do |sc|
  sc.description = "Stationery items"
  sc.is_active = true
  sc.display_order = 1
end

puts "✅ Stationery category ready"

# ============================================
# 4. GET BRANDS, SIZES, COLORS, GENDERS, CONDITIONS
# ============================================
puts "4. Getting brands, sizes, colors, genders, conditions..."

brands = {
  "Pritt" => Brand.find_or_create_by!(name: "Pritt"),
  "Aadil" => Brand.find_or_create_by!(name: "Aadil"),
  "Bic" => Brand.find_or_create_by!(name: "Bic")
}

unisex = Gender.find_by(name: "Unisex") || Gender.find_by(id: 27)
if unisex.nil?
  unisex = Gender.create!(name: "Unisex", category: "standard", display_name: "All", gender_group: "unisex")
end

new_condition = ItemCondition.find_or_create_by!(name: "New") do |ic|
  ic.description = "Brand new item"
end

# ============================================
# 5. CREATE STATIONERY ITEMS FOR MOUNTAIN RIDGE HIGH
# ============================================
puts "5. Creating Mountain Ridge High stationery items..."
puts ""

mr_stationery_items = [
  {
    name: "Aadil Book Covers",
    description: "Aadil book covers for protecting school books. Durable and long-lasting.",
    price: 45.00,
    label: "Book Covers",
    image_prefix: "Aadil_Book_Covers",
    filename: "Aadil_Book_Covers_v1.webp",
    brand: brands["Aadil"],
    gender: unisex,
    sub_category: stationery_sub,
    tags: ["stationery", "books", "school"],
    quantity: 50,
    school: mountain_ridge,
    shop: mr_shop
  },
  {
    name: "Pritt Glue Sticks",
    description: "Pritt glue sticks for craft and school projects. Easy to use and strong adhesive.",
    price: 25.00,
    label: "Glue Sticks",
    image_prefix: "Pritt_Gluesticks",
    filename: "Pritt_Gluesticks_v1.webp",
    brand: brands["Pritt"],
    gender: unisex,
    sub_category: stationery_sub,
    tags: ["stationery", "craft", "school"],
    quantity: 60,
    school: mountain_ridge,
    shop: mr_shop
  }
]

mr_created = 0
mr_stationery_items.each do |item_data|
  folder = "stationery"
  filename = item_data[:filename]
  
  cover_url = "#{CDN_BASE}/schools_demo/mountain-ridge-high/#{folder}/#{filename}"
  additional_url = cover_url

  existing_item = Item.find_by(
    name: item_data[:name],
    school_id: item_data[:school].id
  )

  if existing_item
    existing_item.update!(
      description: item_data[:description],
      price: item_data[:price],
      label: item_data[:label],
      cover_photo: cover_url,
      additional_photo: additional_url,
      label_photo: cover_url,
      shop_id: item_data[:shop]&.id,
      main_category_id: stationery_cat.id,
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
      shop_id: item_data[:shop]&.id,
      school_id: item_data[:school].id,
      main_category_id: stationery_cat.id,
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
    status = "✅ Created"
    mr_created += 1
  end

  # Create variant
  variant_attributes = {
    item_id: item.id,
    condition_id: new_condition.id
  }.compact

  variant = ItemVariant.find_or_create_by!(variant_attributes) do |v|
    v.price = item_data[:price]
    v.quantity = item_data[:quantity]
    v.reserved = 0
    v.is_active = true
    v.sku = "#{item_data[:image_prefix].upcase}-#{SecureRandom.hex(4)}".upcase
    v.metadata = { color: "N/A", size: "One Size" }
  end

  # Add tags
  item_data[:tags].each do |tag_name|
    tag = Tag.find_or_create_by!(name: tag_name) { |t| t.tag_type = "category" }
    ItemTag.find_or_create_by!(item_id: item.id, tag_id: tag.id)
  end

  puts "  #{status}: #{item_data[:name]} (Mountain Ridge High)"
  puts "    📸 Image: #{cover_url}"
  puts "    📁 Category: Stationery"
  puts "    🏷️ Tags: #{item_data[:tags].join(', ')}"
  puts ""
end

# ============================================
# 6. CREATE STATIONERY ITEMS FOR RIVERSIDE COLLEGE
# ============================================
puts "6. Creating Riverside College stationery items..."
puts ""

rc_stationery_items = [
  {
    name: "Labels (RESIZED)",
    description: "Labels for school books and stationery. Perfect for organizing and personalizing.",
    price: 35.00,
    label: "School Labels",
    image_prefix: "Labels-RESIZED",
    filename: "Labels-RESIZED_v1.webp",
    brand: nil,
    gender: unisex,
    sub_category: stationery_sub,
    tags: ["stationery", "labels", "school"],
    quantity: 40,
    school: riverside,
    shop: rc_shop
  }
]

rc_created = 0
rc_stationery_items.each do |item_data|
  folder = "stationery"
  filename = item_data[:filename]
  
  cover_url = "#{CDN_BASE}/schools_demo/river-side-college/#{folder}/#{filename}"
  additional_url = cover_url

  existing_item = Item.find_by(
    name: item_data[:name],
    school_id: item_data[:school].id
  )

  if existing_item
    existing_item.update!(
      description: item_data[:description],
      price: item_data[:price],
      label: item_data[:label],
      cover_photo: cover_url,
      additional_photo: additional_url,
      label_photo: cover_url,
      shop_id: item_data[:shop]&.id,
      main_category_id: stationery_cat.id,
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
      shop_id: item_data[:shop]&.id,
      school_id: item_data[:school].id,
      main_category_id: stationery_cat.id,
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
    status = "✅ Created"
    rc_created += 1
  end

  # Create variant
  variant_attributes = {
    item_id: item.id,
    condition_id: new_condition.id
  }.compact

  variant = ItemVariant.find_or_create_by!(variant_attributes) do |v|
    v.price = item_data[:price]
    v.quantity = item_data[:quantity]
    v.reserved = 0
    v.is_active = true
    v.sku = "#{item_data[:image_prefix].upcase}-#{SecureRandom.hex(4)}".upcase
    v.metadata = { color: "N/A", size: "One Size" }
  end

  # Add tags
  item_data[:tags].each do |tag_name|
    tag = Tag.find_or_create_by!(name: tag_name) { |t| t.tag_type = "category" }
    ItemTag.find_or_create_by!(item_id: item.id, tag_id: tag.id)
  end

  puts "  #{status}: #{item_data[:name]} (Riverside College)"
  puts "    📸 Image: #{cover_url}"
  puts "    📁 Category: Stationery"
  puts "    🏷️ Tags: #{item_data[:tags].join(', ')}"
  puts ""
end

# ============================================
# FINAL SUMMARY
# ============================================
puts "=" * 60
puts "✅ STATIONERY ITEMS SEEDING COMPLETE!"
puts "=" * 60
puts ""
puts "📊 Summary:"
puts "  📚 Mountain Ridge High: #{mr_created} items added"
puts "  📚 Riverside College: #{rc_created} items added"
puts ""
puts "📸 Images Location:"
puts "  Mountain Ridge: #{CDN_BASE}/schools_demo/mountain-ridge-high/stationery/"
puts "  Riverside: #{CDN_BASE}/schools_demo/river-side-college/stationery/"
puts ""
puts "=" * 60