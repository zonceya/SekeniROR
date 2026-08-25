# db/seeds/ironwood_college.rb
puts "🌳 Seeding Ironwood College Items..."
puts "=" * 60

CDN_BASE = "https://cdn.skoolswap.co.za"
school = School.find(16)

sport_cat = MainCategory.find_or_create_by!(name: "Sport")
accessories_cat = MainCategory.find_or_create_by!(name: "Accessories")

sport_sub = SubCategory.find_or_create_by!(name: "Sportswear", main_category_id: sport_cat.id)
accessories_sub = SubCategory.find_or_create_by!(name: "Accessories", main_category_id: accessories_cat.id)

unisex = Gender.find_by(name: "Unisex")
boys = Gender.find_by(name: "Boys")

items = [
  # Sport
  { name: "12 Inch Pump", price: 65.00, filename: "12_Inch_Pump_rugby_v1.webp", folder: "sport", gender: unisex, quantity: 10 },
  { name: "Canterbury Airflow Headgear - Black Senior", price: 280.00, filename: "Canterbury-Airflow-Headgear-Black-Senior-_rugby_v1.webp", folder: "sport", gender: unisex, quantity: 15 },
  { name: "Canterbury Speed Raze Rugby Boots", price: 450.00, filename: "Canterbury_Speed_Raze_Rugby_Boots_rugby_v1.webp", folder: "sport", gender: boys, quantity: 12 },
  { name: "Hybri Rugby Boots", price: 420.00, filename: "Hybri_ Rugby_Boots_rugby_v1.webp", folder: "sport", gender: boys, quantity: 12 },
  { name: "Inflate Pump Needles", price: 15.00, filename: "Inflate_Pump_Needles_rugby_v1.webp", folder: "sport", gender: unisex, quantity: 20 },
  { name: "Jumbo Cone", price: 45.00, filename: "Jumbo_Cone_rugby_v1.webp", folder: "sport", gender: unisex, quantity: 20 },
  { name: "Kicking Tee", price: 85.00, filename: "Kicking_Tee_rugby_v1.webp", folder: "sport", gender: unisex, quantity: 15 },
  
  # Accessories
  { name: "Buttons Sew On", price: 25.00, filename: "Buttons_Sew_On.webp", folder: "accessories", gender: unisex, quantity: 50 },
  { name: "Buttons Sew On (VR1)", price: 25.00, filename: "Buttons_Sew_On_VR1.webp", folder: "accessories", gender: unisex, quantity: 50 },
  { name: "Button Rings", price: 15.00, filename: "button-rings.webp", folder: "accessories", gender: unisex, quantity: 60 }
]

created = 0
items.each do |item_data|
  cover_url = "#{CDN_BASE}/schools_demo/Ironwood-College/#{item_data[:folder]}/#{item_data[:filename]}"
  unless Item.exists?(name: item_data[:name], school_id: school.id)
    main_cat = item_data[:folder] == "sport" ? sport_cat.id : accessories_cat.id
    sub_cat = item_data[:folder] == "sport" ? sport_sub.id : accessories_sub.id
    Item.create!(id: SecureRandom.uuid, name: item_data[:name], description: "#{item_data[:name]} - Ironwood", price: item_data[:price], label: item_data[:name], cover_photo: cover_url, additional_photo: cover_url, label_photo: cover_url, school_id: school.id, main_category_id: main_cat, sub_category_id: sub_cat, gender_id: item_data[:gender]&.id, total_quantity: item_data[:quantity], min_price: item_data[:price], max_price: item_data[:price], status: 1, is_system: true)
    created += 1
  end
end
puts "✅ Ironwood College: #{created} items created"