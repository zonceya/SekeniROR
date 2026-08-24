# db/seeds/ubuntu_community_school.rb
puts "🏫 Seeding Ubuntu Community School Items..."
puts "=" * 60

CDN_BASE = "https://cdn.skoolswap.co.za"
school = School.find(21)

# Categories
uniform_cat = MainCategory.find_or_create_by!(name: "Uniforms")
sport_cat = MainCategory.find_or_create_by!(name: "Sport")
stationery_cat = MainCategory.find_or_create_by!(name: "Stationery")
accessories_cat = MainCategory.find_or_create_by!(name: "Accessories")

uniform_sub = SubCategory.find_or_create_by!(name: "Uniforms", main_category_id: uniform_cat.id)
sport_sub = SubCategory.find_or_create_by!(name: "Sportswear", main_category_id: sport_cat.id)
stationery_sub = SubCategory.find_or_create_by!(name: "Stationery", main_category_id: stationery_cat.id)
books_sub = SubCategory.find_or_create_by!(name: "Books & Notebooks", main_category_id: stationery_cat.id)
calculators_sub = SubCategory.find_or_create_by!(name: "Calculators", main_category_id: stationery_cat.id)
accessories_sub = SubCategory.find_or_create_by!(name: "Accessories", main_category_id: accessories_cat.id)

boys = Gender.find_by(name: "Boys")
girls = Gender.find_by(name: "Girls")
unisex = Gender.find_by(name: "Unisex")

items = [
  # Uniforms
  { name: "Bobby Socks - Girls", price: 65.00, filename: "BOBBY_SOCKS_TOP_girls_v1.webp", folder: "uniform", gender: girls, quantity: 40 },
  { name: "Sleeveless Jersey - Girls", price: 220.00, filename: "JERSEY_SleeveLESS_girls_v1.webp", folder: "uniform", gender: girls, quantity: 20 },
  { name: "Short - Boys", price: 180.00, filename: "SHORT_REY_BOYS_v1.webp", folder: "uniform", gender: boys, quantity: 25 },
  { name: "Socks - Boys", price: 65.00, filename: "SOCKS_BOYS_GREY_ALLWEAR_boys_v1.webp", folder: "uniform", gender: boys, quantity: 40 },
  { name: "School Tie", price: 95.00, filename: "TIE_v1.webp", folder: "uniform", gender: unisex, quantity: 35 },
  { name: "Trousers - Boys", price: 240.00, filename: "TROUSER_BOYS_GREY_v1.webp", folder: "uniform", gender: boys, quantity: 20 },
  { name: "School Dress", price: 250.00, filename: "dress_v1.webp", folder: "uniform", gender: girls, quantity: 15 },
  { name: "Khaki Golf Shirt", price: 180.00, filename: "golf_shirt_khaki_v1.webp", folder: "uniform", gender: unisex, quantity: 30 },
  { name: "Matric Shirt (Short Sleeve)", price: 160.00, filename: "matric_shirt_shirt_sleeve_v1.webp", folder: "uniform", gender: unisex, quantity: 25 },
  { name: "Rain Jacket", price: 320.00, filename: "rain_jacket_v1.webp", folder: "uniform", gender: unisex, quantity: 20 },
  { name: "Short Sleeve Shirt", price: 140.00, filename: "shirt_short_sleeve_v1.webp", folder: "uniform", gender: unisex, quantity: 35 },
  
  # Stationery
  { name: "Mind Action Series Maths Grade 8", price: 120.00, filename: "Mind_Action_Series_Maths_Grade8.webp", folder: "stationary", gender: unisex, quantity: 20, sub: books_sub },
  { name: "Aadil Book Covers", price: 45.00, filename: "Aadil_Book_Covers_v1.webp", folder: "essentials/stationery", gender: unisex, quantity: 50, sub: stationery_sub },
  { name: "Oxford South African Dictionary", price: 320.00, filename: "Oxford_South_African_v1.webp", folder: "essentials/stationery", gender: unisex, quantity: 15, sub: books_sub },
  { name: "Pritt Glue Sticks", price: 25.00, filename: "Pritt_Gluesticks_v1.webp", folder: "essentials/stationery", gender: unisex, quantity: 60, sub: stationery_sub },
  { name: "Typek Paper", price: 85.00, filename: "Typek_Paper_v1.webp", folder: "essentials/stationery", gender: unisex, quantity: 30, sub: stationery_sub },
  
  # Calculator
  { name: "Casio fx-82ZA Calculator", price: 180.00, filename: "Casio_fx-82ZA_Black_v1.webp", folder: "essentials/calculators", gender: unisex, quantity: 25, sub: calculators_sub },
  
  # Accessories
  { name: "Double Sided Apron", price: 85.00, filename: "Double_Sided_Apron.webp", folder: "accessories", gender: unisex, quantity: 25, sub: accessories_sub }
]

created = 0
items.each do |item_data|
  cover_url = "#{CDN_BASE}/schools_demo/ubuntu-community-school/#{item_data[:folder]}/#{item_data[:filename]}"
  sub_cat = item_data[:sub] || uniform_sub
  main_cat = item_data[:folder] == "uniform" ? uniform_cat.id : item_data[:folder].include?("stationery") || item_data[:folder] == "stationary" ? stationery_cat.id : accessories_cat.id
  unless Item.exists?(name: item_data[:name], school_id: school.id)
    Item.create!(id: SecureRandom.uuid, name: item_data[:name], description: "#{item_data[:name]} - Ubuntu", price: item_data[:price], label: item_data[:name], cover_photo: cover_url, additional_photo: cover_url, label_photo: cover_url, school_id: school.id, main_category_id: main_cat, sub_category_id: sub_cat.id, gender_id: item_data[:gender]&.id, total_quantity: item_data[:quantity], min_price: item_data[:price], max_price: item_data[:price], status: 1, is_system: true)
    created += 1
  end
end
puts "✅ Ubuntu Community School: #{created} items created"