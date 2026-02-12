# db/seeds_simple.rb
puts "Starting simplified database seeding..."

# Create provinces
puts "1. Creating provinces..."
Province.find_or_create_by!(name: "Gauteng")
Province.find_or_create_by!(name: "Western Cape")
Province.find_or_create_by!(name: "KwaZulu-Natal")

# Create towns
puts "2. Creating towns..."
gauteng = Province.find_by(name: "Gauteng")
Town.find_or_create_by!(name: "Johannesburg", province: gauteng)
Town.find_or_create_by!(name: "Pretoria", province: gauteng)

# Create locations
puts "3. Creating locations..."
jhb_town = Town.find_by(name: "Johannesburg")
Location.find_or_create_by!(province: "Gauteng", town: jhb_town)

# Create users
puts "4. Creating users..."
user1 = User.find_or_create_by!(email: "shopowner@example.com") do |u|
  u.name = "Shop Owner"
  u.password_digest = BCrypt::Password.create("password123")
  u.role = "user"
  u.status = true
end

user2 = User.find_or_create_by!(email: "buyer@example.com") do |u|
  u.name = "Buyer User"
  u.password_digest = BCrypt::Password.create("password123")
  u.role = "user"
  u.status = true
end

# Create profiles
puts "5. Creating profiles..."
Profile.find_or_create_by!(user: user1) do |p|
  p.mobile = "+27123456789"
end

Profile.find_or_create_by!(user: user2) do |p|
  p.mobile = "+27876543210"
end

# Create shops
puts "6. Creating shops..."
shop = Shop.find_or_create_by!(user: user1) do |s|
  s.name = "Test Shop"
  s.description = "A test shop for development"
  s.location = "Gauteng"
end

# Create main categories
puts "7. Creating main categories..."
sports = MainCategory.find_or_create_by!(name: "Sports Gear") do |mc|
  mc.description = "Sports equipment and uniforms"
  mc.icon_name = "sports_soccer"
  mc.is_active = true
  mc.display_order = 1
end

# Create sub categories
puts "8. Creating sub categories..."
sports_uniforms = SubCategory.find_or_create_by!(name: "Sports Uniforms") do |sc|
  sc.description = "Official sports uniforms"
  sc.main_category = sports
  sc.is_active = true
  sc.display_order = 1
end

# Create brands
puts "9. Creating brands..."
Brand.find_or_create_by!(name: "Nike")
Brand.find_or_create_by!(name: "Adidas")

# Create item conditions
puts "10. Creating item conditions..."
ItemCondition.find_or_create_by!(name: "New") do |ic|
  ic.description = "Brand new item"
end

ItemCondition.find_or_create_by!(name: "Used - Like New") do |ic|
  ic.description = "Gently used, looks new"
end

# Create item sizes
puts "11. Creating item sizes..."
ItemSize.find_or_create_by!(name: "S")
ItemSize.find_or_create_by!(name: "M")
ItemSize.find_or_create_by!(name: "L")

# Create item colors
puts "12. Creating item colors..."
ItemColor.find_or_create_by!(name: "Red")
ItemColor.find_or_create_by!(name: "Blue")
ItemColor.find_or_create_by!(name: "White")

# Create genders
puts "13. Creating genders..."
Gender.find_or_create_by!(name: "Boys") do |g|
  g.category = "standard"
  g.display_name = "Boys"
  g.gender_group = "male"
end

Gender.find_or_create_by!(name: "Girls") do |g|
  g.category = "standard"
  g.display_name = "Girls"
  g.gender_group = "female"
end

# Create schools
puts "14. Creating schools..."
location = Location.first
province = Province.first
School.find_or_create_by!(name: "Test School") do |s|
  s.location = location
  s.school_type = "high"
  s.province = province
end

# Create tags
puts "15. Creating tags..."
Tag.find_or_create_by!(name: "soccer") do |t|
  t.tag_type = "sport"
end

Tag.find_or_create_by!(name: "school team") do |t|
  t.tag_type = "team"
end

Tag.find_or_create_by!(name: "uniform") do |t|
  t.tag_type = "category"
end

# Create a sample item
puts "16. Creating a sample item..."
item = Item.find_or_create_by!(name: "Boys Soccer Jersey", shop: shop) do |i|
  i.description = "Official school soccer jersey"
  i.price = 45.00
  i.quantity = 10
  i.reserved = 0
  i.status = 1
  i.main_category = sports
  i.sub_category = sports_uniforms
  i.gender = Gender.find_by(name: "Boys")
  i.school = School.first
  i.brand = Brand.find_by(name: "Nike")
  i.size = ItemSize.find_by(name: "M")
  i.item_condition = ItemCondition.find_by(name: "New")
  i.location = location
  i.province = province
  i.meta = {color: "Red", size: "M"}
end

# Create item tags
puts "17. Creating item tags..."
ItemTag.find_or_create_by!(item: item, tag: Tag.find_by(name: "soccer"))
ItemTag.find_or_create_by!(item: item, tag: Tag.find_by(name: "school team"))

puts "=" * 50
puts "Simplified seeding complete!"
puts "=" * 50
