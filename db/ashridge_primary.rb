# db/seeds/ashridge_primary.rb
puts "🏫 Seeding Ashridge Primary Items..."
puts "=" * 60

CDN_BASE = "https://cdn.skoolswap.co.za"
school = School.find(18)

uniform_cat = MainCategory.find_or_create_by!(name: "Uniforms")
sport_cat = MainCategory.find_or_create_by!(name: "Sport")
accessories_cat = MainCategory.find_or_create_by!(name: "Accessories")

uniform_sub = SubCategory.find_or_create_by!(name: "Uniforms", main_category_id: uniform_cat.id)
sport_sub = SubCategory.find_or_create_by!(name: "Sportswear", main_category_id: sport_cat.id)
accessories_sub = SubCategory.find_or_create_by!(name: "Accessories", main_category_id: accessories_cat.id)

boys = Gender.find_by(name: "Boys")
girls = Gender.find_by(name: "Girls")
unisex = Gender.find_by(name: "Unisex")

items = [
  # Uniforms
  { name: "Fleece", price: 280.00, filename: "Fleece_v1.webp", folder: "uniform", gender: unisex, quantity: 25 },
  
  # Sport
  { name: "1st Team Socks", price: 65.00, filename: "1st-Team-Socks-Version-v1.webp", folder: "sport", gender: unisex, quantity: 30 },
  { name: "1st Team Cricket Cap", price: 120.00, filename: "1st_Team_Cricket_Team_Baggy_Caps_v1.webp", folder: "sport", gender: unisex, quantity: 15 },
  { name: "Midi Rugby Ball", price: 180.00, filename: "Midi_Rugby_Ball_rugby_v1.webp", folder: "sport", gender: unisex, quantity: 10 },
  { name: "Plastic Whistle", price: 25.00, filename: "Plastic_Whistle_rugby_v1.webp", folder: "sport", gender: unisex, quantity: 20 },
  { name: "Protective Shoulder Pads - Junior", price: 320.00, filename: "Protective_Shoulder_Pads_Junior_rugby_v1.webp", folder: "sport", gender: boys, quantity: 10 },
  { name: "Puma Thermo Player Glove", price: 150.00, filename: "Puma-thermo-player-glove-_rugby_v1.webp", folder: "sport", gender: unisex, quantity: 15 },
  { name: "Rugby High Tee - Red", price: 85.00, filename: "Rugby_High_Tee _RedDECATHLON _CANTERBURY_rugby_v1.webp", folder: "sport", gender: unisex, quantity: 12 },
  { name: "Rugby Top", price: 220.00, filename: "Rugby_Top_v1.webp", folder: "sport", gender: unisex, quantity: 20 },
  { name: "Sport Socks", price: 55.00, filename: "Sport-Socks-Version-v1.webp", folder: "sport", gender: unisex, quantity: 40 },
  { name: "Boys PE Top", price: 120.00, filename: "boys-pe-top-1-v1.webp", folder: "sport", gender: boys, quantity: 25 },
  { name: "Cricket Top", price: 180.00, filename: "cricket-top-v1.webp", folder: "sport", gender: unisex, quantity: 20 },
  { name: "Tracksuit Pants", price: 160.00, filename: "tracksuit-pants-v1.webp", folder: "sport", gender: unisex, quantity: 20 },
  { name: "Tracksuit Top", price: 200.00, filename: "tracksuit-top-v1.webp", folder: "sport", gender: unisex, quantity: 20 },
  
  # Essentials
  { name: "Peak Cap", price: 95.00, filename: "Peak _Cap_v1.webp", folder: "essentials", gender: unisex, quantity: 30 },
  { name: "Tennis Peak Cap", price: 110.00, filename: "Tennis_Peak_Cap_v1.webp", folder: "essentials", gender: unisex, quantity: 25 },
  
  # Accessories
  { name: "Art Apron", price: 85.00, filename: "Art_Apron_v1.webp", folder: "accessories", gender: unisex, quantity: 25 },
  { name: "Chilloes Supporter Flip-Flops", price: 65.00, filename: "Chilloes_Supporter_Flip-Flops_v1.webp", folder: "accessories", gender: unisex, quantity: 20 },
  { name: "Music Bag", price: 140.00, filename: "Music-Bag_v1.webp", folder: "accessories", gender: unisex, quantity: 15 },
  { name: "Scarf", price: 95.00, filename: "Scarf-Version-v1.webp", folder: "accessories", gender: unisex, quantity: 30 },
  { name: "School Bag", price: 180.00, filename: "School_Bag_v1.webp", folder: "accessories", gender: unisex, quantity: 20 }
]

created = 0
items.each do |item_data|
  cover_url = "#{CDN_BASE}/schools_demo/ashridge-primary/#{item_data[:folder]}/#{item_data[:filename]}"
  unless Item.exists?(name: item_data[:name], school_id: school.id)
    main_cat = item_data[:folder] == "uniform" ? uniform_cat.id : item_data[:folder] == "sport" ? sport_cat.id : accessories_cat.id
    sub_cat = item_data[:folder] == "uniform" ? uniform_sub.id : item_data[:folder] == "sport" ? sport_sub.id : accessories_sub.id
    Item.create!(id: SecureRandom.uuid, name: item_data[:name], description: "#{item_data[:name]} - Ashridge", price: item_data[:price], label: item_data[:name], cover_photo: cover_url, additional_photo: cover_url, label_photo: cover_url, school_id: school.id, main_category_id: main_cat, sub_category_id: sub_cat, gender_id: item_data[:gender]&.id, total_quantity: item_data[:quantity], min_price: item_data[:price], max_price: item_data[:price], status: 1, is_system: true)
    created += 1
  end
end
puts "✅ Ashridge Primary: #{created} items created"