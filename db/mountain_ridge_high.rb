# db/seeds/mountain_ridge_high.rb
puts "🏔️ Seeding Mountain Ridge High Items..."
puts "=" * 60

CDN_BASE = "https://cdn.skoolswap.co.za"
school = School.find(14)

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

items = [
  # Uniforms
  { name: "Fleece Jacket", price: 350.00, filename: "Fleece_Jacket_v1.webp", folder: "uniform", gender: unisex, quantity: 20 },
  { name: "Arena Visor Cap", price: 120.00, filename: "arena_visor_cap_v1.webp", folder: "uniform", gender: unisex, quantity: 35 },
  { name: "Durafast Swim Cap", price: 95.00, filename: "durafast_swim_cap_v1.webp", folder: "uniform", gender: unisex, quantity: 30 },
  { name: "Embroidered Badge", price: 45.00, filename: "emboided_bap_v1.webp", folder: "uniform", gender: unisex, quantity: 50 },
  { name: "Long Sleeve Golf Shirt", price: 280.00, filename: "golf_shirt_long_v1.webp.webp", folder: "uniform", gender: unisex, quantity: 20 },
  { name: "Golf Shirt", price: 220.00, filename: "golf_shirt_v1.webp.png", folder: "uniform", gender: unisex, quantity: 30 },
  { name: "Jersey", price: 250.00, filename: "jersey_v1.webp", folder: "uniform", gender: unisex, quantity: 25 },
  { name: "Kangaroo Hoodie", price: 280.00, filename: "kangaroo_hoodie_v1.webp", folder: "uniform", gender: unisex, quantity: 25 },
  { name: "Pleated Skirt", price: 180.00, filename: "pleaded_skirt_v1.webp", folder: "uniform", gender: girls, quantity: 15 },
  { name: "Skirt", price: 160.00, filename: "skirt_v1.webp", folder: "uniform", gender: girls, quantity: 20 },
  { name: "Zip Hoodie", price: 320.00, filename: "zip_hoodie_v1.webp", folder: "uniform", gender: unisex, quantity: 20 },
  
  # Stationery
  { name: "Aadil Book Covers", price: 45.00, filename: "Aadil_Book_Covers_v1.webp", folder: "stationery", gender: unisex, quantity: 50 },
  { name: "Pritt Glue Sticks", price: 25.00, filename: "Pritt_Gluesticks_v1.webp", folder: "stationery", gender: unisex, quantity: 60 },
  
  # Accessories
  { name: "Beanie", price: 85.00, filename: "beane_v1.webp", folder: "accessories", gender: unisex, quantity: 40 },
  { name: "Scarf", price: 95.00, filename: "scarf_v1.webp", folder: "accessories", gender: unisex, quantity: 35 },
  { name: "Shopping Bag", price: 45.00, filename: "shopping_bag_v1.webp", folder: "accessories", gender: unisex, quantity: 50 },
  { name: "Sport Bag", price: 180.00, filename: "sport_bag_v1.webp", folder: "accessories", gender: unisex, quantity: 25 }
]

created = 0
items.each do |item_data|
  cover_url = "#{CDN_BASE}/schools_demo/mountain-ridge-high/#{item_data[:folder]}/#{item_data[:filename]}"
  unless Item.exists?(name: item_data[:name], school_id: school.id)
    Item.create!(id: SecureRandom.uuid, name: item_data[:name], description: "#{item_data[:name]} - Mountain Ridge High", price: item_data[:price], label: item_data[:name], cover_photo: cover_url, additional_photo: cover_url, label_photo: cover_url, school_id: school.id, main_category_id: item_data[:folder] == "uniform" ? uniform_cat.id : item_data[:folder] == "stationery" ? stationery_cat.id : accessories_cat.id, sub_category_id: item_data[:folder] == "uniform" ? uniform_sub.id : item_data[:folder] == "stationery" ? stationery_sub.id : accessories_sub.id, gender_id: item_data[:gender]&.id, total_quantity: item_data[:quantity], min_price: item_data[:price], max_price: item_data[:price], status: 1, is_system: true)
    created += 1
  end
end
puts "✅ Mountain Ridge High: #{created} items created"