# ============================================
# 13. CREATE ITEMS (FIXED VERSION)
# ============================================
puts "\n📦 13. Creating sample items..."

schools = School.all
shops = Shop.all
genders = Gender.all
conditions = ItemCondition.all
sizes = ItemSize.all
colors = ItemColor.all
brands = Brand.all

# Get categories
uniform_cat = MainCategory.find_by(name: "Uniforms")
sport_cat = MainCategory.find_by(name: "Sport")
textbook_cat = MainCategory.find_by(name: "Textbooks")

items_created = 0

# Create UNIFORM items
5.times do |i|
  school = schools.sample
  gender = genders.where(category: ['primary', 'high']).sample
  
  Item.create!(
    name: "#{school.name} #{gender&.display_name || 'Student'} Uniform",
    description: "Official school uniform",
    shop: shops.sample,
    school: school,
    main_category: uniform_cat,
    sub_category: uniform_cat.sub_categories.sample,
    gender: gender,
    brand: brands.sample,
    price: rand(300..800),
    total_quantity: rand(5..20),
    status: 1,
    location_id: school.location_id,  # ✅ FIXED: use location_id
    province_id: school.province_id,  # ✅ FIXED: use province_id
    meta: { age_group: gender&.exact_age ? "#{gender.exact_age-1}-#{gender.exact_age+1}" : "6-12" }
  )
  items_created += 1
  print "."
end

# Create SPORT items
5.times do |i|
  school = schools.sample
  sport = ["Rugby", "Cricket", "Hockey", "Netball", "Soccer"].sample
  gender = genders.where(category: 'high').sample
  
  Item.create!(
    name: "#{school.name} #{sport} Jersey",
    description: "#{sport} jersey for #{school.name}",
    shop: shops.sample,
    school: school,
    main_category: sport_cat,
    sub_category: sport_cat.sub_categories.find_by("name ILIKE ?", "%#{sport}%") || sport_cat.sub_categories.sample,
    gender: gender,
    brand: brands.where(name: ["Nike", "Adidas", "Puma"]).sample,
    price: rand(400..1200),
    total_quantity: rand(3..15),
    status: 1,
    location_id: school.location_id,  # ✅ FIXED: use location_id
    province_id: school.province_id,  # ✅ FIXED: use province_id
    meta: { sport: sport.downcase, age_group: "13-18" }
  )
  items_created += 1
  print "."
end

puts "\n   ✅ Created #{items_created} items"