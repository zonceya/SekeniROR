# db/seeds/riverside_college.rb
puts "🌊 Seeding Riverside College Items..."
puts "=" * 60

CDN_BASE = "https://cdn.skoolswap.co.za"
school = School.find(15)

# Categories
uniform_cat = MainCategory.find_or_create_by!(name: "Uniforms")
sport_cat = MainCategory.find_or_create_by!(name: "Sport")
stationery_cat = MainCategory.find_or_create_by!(name: "Stationery")
accessories_cat = MainCategory.find_or_create_by!(name: "Accessories")

uniform_sub = SubCategory.find_or_create_by!(name: "Uniforms", main_category_id: uniform_cat.id)
sport_sub = SubCategory.find_or_create_by!(name: "Sportswear", main_category_id: sport_cat.id)
stationery_sub = SubCategory.find_or_create_by!(name: "Stationery", main_category_id: stationery_cat.id)
accessories_sub = SubCategory.find_or_create_by!(name: "Accessories", main_category_id: accessories_cat.id)

boys = Gender.find_by(name: "Boys")
girls = Gender.find_by(name: "Girls")
unisex = Gender.find_by(name: "Unisex")

# Riverside items (45 items - simplified for brevity)
items = [
  # Uniforms (12 items)
  { name: "Black Belt", price: 45.00, filename: "BLACK_BELT_v1.webp", folder: "uniform", gender: unisex, quantity: 40 },
  { name: "Golf Shirt", price: 220.00, filename: "GOLF_SHIRT_v1.webp", folder: "uniform", gender: unisex, quantity: 30 },
  { name: "Green Cross Lace Up School Shoe", price: 350.00, filename: "GREEN_CROSS_LACE_UP_SCHOOL_SHOE_v1.webp", folder: "uniform", gender: unisex, quantity: 25 },
  { name: "Grey School Shorts", price: 180.00, filename: "GREY_SCHOOL_SHORTS_v1.webp", folder: "uniform", gender: boys, quantity: 30 },
  { name: "Grey Trousers", price: 240.00, filename: "Grey_TROUSERS_v1.webp", folder: "uniform", gender: boys, quantity: 20 },
  { name: "Jersey", price: 250.00, filename: "JERSEY_v1.webp", folder: "uniform", gender: unisex, quantity: 25 },
  { name: "Long Sleeve School Shirt", price: 160.00, filename: "LONG_SLEEVE_SCHOOL_SHIRT_v1.webp", folder: "uniform", gender: unisex, quantity: 35 },
  { name: "Navy Blazer", price: 450.00, filename: "NAVY_BLAZER_v1.webp", folder: "uniform", gender: unisex, quantity: 15 },
  { name: "Navy Trousers", price: 240.00, filename: "NAVY_TROUSERS_v1.webp", folder: "uniform", gender: boys, quantity: 20 },
  { name: "School Shirt", price: 140.00, filename: "SCHOOL_SHIRT_v1.webp", folder: "uniform", gender: unisex, quantity: 40 },
  { name: "Toughees Lace Up Black School Shoe", price: 380.00, filename: "TOUGHEES_LACE_UP_BLACK_SCHOOL_SHOE_v1 (2).webp", folder: "uniform", gender: unisex, quantity: 25 },
  { name: "Tracksuit Top", price: 280.00, filename: "TRACKSUIT_TOP_v1.webp", folder: "uniform", gender: unisex, quantity: 20 },
  
  # Sport (21 items - simplified)
  { name: "Blue Sport Vest", price: 85.00, filename: "Blue_Sport_VEST_v1.webp", folder: "sport", gender: unisex, quantity: 30 },
  { name: "Canterbury Z-Vest Shoulder Vest - Junior Black", price: 120.00, filename: "CANTERBURY-Z-VEST-SHOULDER-VEST-JUNIOR-BLACK-_rugby_v1.webp", folder: "sport", gender: boys, quantity: 20 },
  { name: "Cricket Cap", price: 120.00, filename: "CRICKET_CAP_v1.webp", folder: "sport", gender: unisex, quantity: 30 },
  { name: "Cricket Jersey", price: 240.00, filename: "CRICKET_JERSEY_v1.webp", folder: "sport", gender: unisex, quantity: 20 },
  { name: "Elite 95 Supertee Rugby", price: 180.00, filename: "Elite_95_Supertee_rugby_v1.webp", folder: "sport", gender: boys, quantity: 20 },
  { name: "Finger Whistle", price: 35.00, filename: "Finger_Whistle_rugby_v1.webp", folder: "sport", gender: unisex, quantity: 15 },
  { name: "Gilbert G-tr 3000 Rugby Ball", price: 280.00, filename: "Gilbert_G-tr_3000_Rugby_Ball_rugby_v1.webp", folder: "sport", gender: unisex, quantity: 10 },
  { name: "Green Sport Vest", price: 85.00, filename: "Green_Sport_VEST_v1.webp", folder: "sport", gender: unisex, quantity: 30 },
  { name: "Hybri Rugby Boots", price: 450.00, filename: "Hybri_ Rugby_Boots_rugby_v1.webp", folder: "sport", gender: boys, quantity: 15 },
  { name: "Long Sport Sock", price: 65.00, filename: "LONG_SPORT_SOCK_v1.webp", folder: "sport", gender: unisex, quantity: 40 },
  { name: "Navy Long Sport Sock", price: 65.00, filename: "NAVY_LONG_SPORT_SOCK_v1.webp", folder: "sport", gender: unisex, quantity: 40 },
  { name: "Navy Rugby Shorts", price: 180.00, filename: "NAVY_RUGBY_SHORTS_v1.webp", folder: "sport", gender: boys, quantity: 25 },
  { name: "Navy Sport Vest", price: 85.00, filename: "Navy_sport_Vest_v1.webp", folder: "sport", gender: unisex, quantity: 30 },
  { name: "Pink Sport Vest", price: 85.00, filename: "Pink_Sport_Vest_v1.webp", folder: "sport", gender: girls, quantity: 30 },
  { name: "Purple Sport Vest", price: 85.00, filename: "Purple_Sport_Vest_v1.webp", folder: "sport", gender: unisex, quantity: 30 },
  { name: "Rugby Jersey", price: 280.00, filename: "RUGBY_JERSEY_v1.webp", folder: "sport", gender: unisex, quantity: 20 },
  { name: "Red Sport Vest", price: 85.00, filename: "Red_Sport_VEST_v1.webp", folder: "sport", gender: unisex, quantity: 30 },
  { name: "Swimming Costume", price: 180.00, filename: "SWIMMING_COSTUME_v1.webp", folder: "sport", gender: girls, quantity: 15 },
  { name: "White Rugby Shorts", price: 180.00, filename: "WHITE_RUGBY_SHORT_v1.webp", folder: "sport", gender: boys, quantity: 25 },
  { name: "White Rugby Shorts (Gilbert)", price: 200.00, filename: "White_Rugbuy_shorts_Gilbert_v1.webp", folder: "sport", gender: boys, quantity: 20 },
  
  # Stationery (6 items)
  { name: "Labels (RESIZED)", price: 35.00, filename: "Labels-RESIZED_v1.webp", folder: "stationery", gender: unisex, quantity: 50 },
  { name: "Colop DIY Marky Stamp - Textile School Marker", price: 55.00, filename: "colop-diy-marky-stamp-textile-school-marker-green-pink-mood--v1.webp", folder: "stationery", gender: unisex, quantity: 30 },
  { name: "Colop Marky Stamp Refill Kit", price: 25.00, filename: "colop-marky-stamp-refill-kit-textile-school-marker-02_V1.webp", folder: "stationery", gender: unisex, quantity: 40 },
  { name: "Colop Marky Stamp - Textile School Marker Green", price: 45.00, filename: "colop-marky-stamp-textile-school-marker-green_v1.webp", folder: "stationery", gender: unisex, quantity: 30 },
  { name: "Marker G8 Step 5", price: 30.00, filename: "marker-g8-step-5-gru-n_ge5v-v1.webp", folder: "stationery", gender: unisex, quantity: 35 },
  { name: "Stamp Marker", price: 40.00, filename: "stamp-marker-v1.webp", folder: "stationery", gender: unisex, quantity: 30 },
  
  # Essentials (4 items)
  { name: "Grey Anklet School Sock", price: 55.00, filename: "GREY_ANKLET_SCHOOL_SOCK_v1.webp", folder: "essentials", gender: unisex, quantity: 45 },
  { name: "School Scarf", price: 95.00, filename: "SCHOOL_SCARF_v1.webp", folder: "essentials", gender: unisex, quantity: 35 },
  { name: "School Tie", price: 95.00, filename: "SCHOOL_TIE_v1.webp", folder: "essentials", gender: unisex, quantity: 35 },
  { name: "Striped Tie", price: 85.00, filename: "Sriped_Tie_v1.webp", folder: "essentials", gender: unisex, quantity: 30 },
  
  # Accessories (3 items)
  { name: "Laundry Bag", price: 65.00, filename: "LAUNDRY_BAG_v1.webp", folder: "accessories", gender: unisex, quantity: 25 },
  { name: "Sock Bag", price: 45.00, filename: "SOCK_BAG_v1.webp", folder: "accessories", gender: unisex, quantity: 30 },
  { name: "Trunk", price: 120.00, filename: "Trunk_v1.webp", folder: "accessories", gender: unisex, quantity: 15 }
]

created = 0
items.each do |item_data|
  cover_url = "#{CDN_BASE}/schools_demo/river-side-college/#{item_data[:folder]}/#{item_data[:filename]}"
  unless Item.exists?(name: item_data[:name], school_id: school.id)
    Item.create!(id: SecureRandom.uuid, name: item_data[:name], description: "#{item_data[:name]} - Riverside College", price: item_data[:price], label: item_data[:name], cover_photo: cover_url, additional_photo: cover_url, label_photo: cover_url, school_id: school.id, main_category_id: item_data[:folder] == "uniform" ? uniform_cat.id : item_data[:folder] == "sport" ? sport_cat.id : item_data[:folder] == "stationery" ? stationery_cat.id : accessories_cat.id, sub_category_id: item_data[:folder] == "uniform" ? uniform_sub.id : item_data[:folder] == "sport" ? sport_sub.id : item_data[:folder] == "stationery" ? stationery_sub.id : accessories_sub.id, gender_id: item_data[:gender]&.id, total_quantity: item_data[:quantity], min_price: item_data[:price], max_price: item_data[:price], status: 1, is_system: true)
    created += 1
  end
end
puts "✅ Riverside College: #{created} items created"