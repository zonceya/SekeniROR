# db/seeds/willowcrest.rb
puts "🌿 Seeding Willowcrest Items..."
puts "=" * 60

CDN_BASE = "https://cdn.skoolswap.co.za"
school = School.find(22)

uniform_cat = MainCategory.find_or_create_by!(name: "Uniforms")
sport_cat = MainCategory.find_or_create_by!(name: "Sport")
stationery_cat = MainCategory.find_or_create_by!(name: "Stationery")
accessories_cat = MainCategory.find_or_create_by!(name: "Accessories")

uniform_sub = SubCategory.find_or_create_by!(name: "Uniforms", main_category_id: uniform_cat.id)
sport_sub = SubCategory.find_or_create_by!(name: "Sportswear", main_category_id: sport_cat.id)
stationery_sub = SubCategory.find_or_create_by!(name: "Stationery", main_category_id: stationery_cat.id)
accessories_sub = SubCategory.find_or_create_by!(name: "Accessories", main_category_id: accessories_cat.id)

girls = Gender.find_by(name: "Girls")
unisex = Gender.find_by(name: "Unisex")

items = [
  # Uniforms
  { name: "Girls White Socks", price: 65.00, filename: "girls-white-socks-v1.webp", folder: "uniform", gender: girls, quantity: 40 },
  { name: "Hot Pants - Girls", price: 120.00, filename: "hot_pants_lr-min-girls-v1.webp", folder: "uniform", gender: girls, quantity: 25 },
  
  # Stationery
  { name: "Coloring Book - Grade 1", price: 45.00, filename: "Bond_bk_Gr1_lr-coloringbook-min-v1.webp", folder: "stationery", gender: unisex, quantity: 30 },
  
  # Sport
  { name: "Girls Sport Shorts (Black)", price: 110.00, filename: "Shorts_School_blk_lr-min-grils-v1.webp", folder: "sport", gender: girls, quantity: 30 },
  { name: "Girls Swim Suit", price: 180.00, filename: "girl-swimsuite-v1.webp", folder: "sport", gender: girls, quantity: 15 },
  { name: "Girls Hockey Socks", price: 75.00, filename: "girls-hockey-socks-v1.webp", folder: "sport", gender: girls, quantity: 35 },
  { name: "Girls Sport Socks", price: 65.00, filename: "girls-sport-socks-v1.webp", folder: "sport", gender: girls, quantity: 40 },
  { name: "Girls PE Shorts", price: 100.00, filename: "shorts_PE_lr-min-girls-v1.webp", folder: "sport", gender: girls, quantity: 30 },
  { name: "Girls Black School Socks", price: 65.00, filename: "socks_black_school_lr-girls-v1.webp", folder: "sport", gender: girls, quantity: 40 },
  { name: "Girls Tracksuit Pants", price: 180.00, filename: "tracksuit-pants_lr-min-girls-v1.webp", folder: "sport", gender: girls, quantity: 20 },
  
  # Accessories
  { name: "Apron", price: 85.00, filename: "APRON.webp", folder: "accessories", gender: unisex, quantity: 25 },
  { name: "Blazer Buttons (Set)", price: 35.00, filename: "BLAZER_BUTTONS_RINGS.webp", folder: "accessories", gender: unisex, quantity: 50 },
  { name: "Blazer Button", price: 15.00, filename: "Blazer_button.webp", folder: "accessories", gender: unisex, quantity: 60 }
]

created = 0
items.each do |item_data|
  cover_url = "#{CDN_BASE}/schools_demo/willowcrest/#{item_data[:folder]}/#{item_data[:filename]}"
  unless Item.exists?(name: item_data[:name], school_id: school.id)
    Item.create!(id: SecureRandom.uuid, name: item_data[:name], description: "#{item_data[:name]} - Willowcrest", price: item_data[:price], label: item_data[:name], cover_photo: cover_url, additional_photo: cover_url, label_photo: cover_url, school_id: school.id, main_category_id: item_data[:folder] == "uniform" ? uniform_cat.id : item_data[:folder] == "sport" ? sport_cat.id : item_data[:folder] == "stationery" ? stationery_cat.id : accessories_cat.id, sub_category_id: item_data[:folder] == "uniform" ? uniform_sub.id : item_data[:folder] == "sport" ? sport_sub.id : item_data[:folder] == "stationery" ? stationery_sub.id : accessories_sub.id, gender_id: item_data[:gender]&.id, total_quantity: item_data[:quantity], min_price: item_data[:price], max_price: item_data[:price], status: 1, is_system: true)
    created += 1
  end
end
puts "✅ Willowcrest: #{created} items created"