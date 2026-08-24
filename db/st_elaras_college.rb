# db/seeds/st_elaras_college.rb
puts "🏫 Seeding St. Elara's College Items..."
puts "=" * 60

CDN_BASE = "https://cdn.skoolswap.co.za"
school = School.find(17)

uniform_cat = MainCategory.find_or_create_by!(name: "Uniforms")
sport_cat = MainCategory.find_or_create_by!(name: "Sport")
accessories_cat = MainCategory.find_or_create_by!(name: "Accessories")
footwear_cat = MainCategory.find_or_create_by!(name: "Footwear")

uniform_sub = SubCategory.find_or_create_by!(name: "Uniforms", main_category_id: uniform_cat.id)
sport_sub = SubCategory.find_or_create_by!(name: "Sportswear", main_category_id: sport_cat.id)
accessories_sub = SubCategory.find_or_create_by!(name: "Accessories", main_category_id: accessories_cat.id)
footwear_sub = SubCategory.find_or_create_by!(name: "School Shoes", main_category_id: footwear_cat.id)

boys = Gender.find_by(name: "Boys")
girls = Gender.find_by(name: "Girls")
unisex = Gender.find_by(name: "Unisex")

items = [
  # Uniforms
  { name: "Bottle Green Rugby Shirt (Gr 1-3)", price: 180.00, filename: "Bottle-Green-Rugby-Shirt-Gr-1-2-3_v1.webp", folder: "uniform", gender: unisex, quantity: 20 },
  { name: "Boys Jammers", price: 160.00, filename: "Boys-Jammers-v1.webp", folder: "uniform", gender: boys, quantity: 15 },
  { name: "Boys New Shirt", price: 140.00, filename: "Boys-New-Shirt-v1.webp", folder: "uniform", gender: boys, quantity: 30 },
  { name: "Boys White Sport Shorts", price: 110.00, filename: "Boys-White-Sport-Shorts-v1.webp", folder: "uniform", gender: boys, quantity: 25 },
  { name: "Girls Shorts Green", price: 110.00, filename: "Girls-Shorts-Green-v1.webp", folder: "uniform", gender: girls, quantity: 25 },
  { name: "Girls Uniform White Socks", price: 55.00, filename: "Girls-Uniform-White-Socks-v1.webp", folder: "uniform", gender: girls, quantity: 40 },
  { name: "New Sports Sock", price: 55.00, filename: "New-Sports-Sock-v1.webp", folder: "uniform", gender: unisex, quantity: 40 },
  { name: "Stockings", price: 65.00, filename: "Stockings-v1.webp", folder: "uniform", gender: girls, quantity: 30 },
  { name: "Toughees Girls School Shoes", price: 350.00, filename: "Toughees-Girls-School-v1.webp", folder: "uniform", gender: girls, quantity: 20 },
  
  # Sport
  { name: "Boys Rugby Jersey", price: 220.00, filename: "Boys-Rugby-Jersey-v1.webp", folder: "sport", gender: boys, quantity: 20 },
  
  # Footwear
  { name: "Black Slops", price: 85.00, filename: "Black-Slops-v1.webp", folder: "footwear", gender: unisex, quantity: 25 },
  { name: "Hush Puppies School Shoes", price: 380.00, filename: "Hush-Puppies-v1.webp", folder: "footwear", gender: unisex, quantity: 20 },
  { name: "Toughees School Shoes", price: 350.00, filename: "Toughees-Girls-School-v1.webp", folder: "footwear", gender: girls, quantity: 20 },
  
  # Accessories
  { name: "Art Apron", price: 85.00, filename: "Art_Apron_v1.webp", folder: "accessories", gender: unisex, quantity: 25 },
  { name: "Gum Guard - BadBoy", price: 45.00, filename: "Gum-Guard-BadBoy-v1.webp", folder: "accessories", gender: unisex, quantity: 30 },
  { name: "Rain Poncho Uniform", price: 120.00, filename: "Rain-Poncho-Uniform-v1.webp", folder: "accessories", gender: unisex, quantity: 20 }
]

created = 0
items.each do |item_data|
  cover_url = "#{CDN_BASE}/schools_demo/St._Elara’s_College/#{item_data[:folder]}/#{item_data[:filename]}"
  unless Item.exists?(name: item_data[:name], school_id: school.id)
    main_cat = item_data[:folder] == "uniform" ? uniform_cat.id : item_data[:folder] == "sport" ? sport_cat.id : item_data[:folder] == "footwear" ? footwear_cat.id : accessories_cat.id
    sub_cat = item_data[:folder] == "uniform" ? uniform_sub.id : item_data[:folder] == "sport" ? sport_sub.id : item_data[:folder] == "footwear" ? footwear_sub.id : accessories_sub.id
    Item.create!(id: SecureRandom.uuid, name: item_data[:name], description: "#{item_data[:name]} - St. Elara's", price: item_data[:price], label: item_data[:name], cover_photo: cover_url, additional_photo: cover_url, label_photo: cover_url, school_id: school.id, main_category_id: main_cat, sub_category_id: sub_cat, gender_id: item_data[:gender]&.id, total_quantity: item_data[:quantity], min_price: item_data[:price], max_price: item_data[:price], status: 1, is_system: true)
    created += 1
  end
end
puts "✅ St. Elara's College: #{created} items created"