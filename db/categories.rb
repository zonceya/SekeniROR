# db/seeds/categories.rb
puts "Creating school-focused categories..."

# Main Categories for School Marketplace
main_categories = [
  { name: "School Uniforms", description: "Official school uniforms and attire", icon_name: "uniform", display_order: 1 },
  { name: "Books & Stationery", description: "Textbooks, workbooks, and writing materials", icon_name: "books", display_order: 2 },
  { name: "Sports Gear", description: "Sports equipment and athletic wear", icon_name: "sports", display_order: 3 },
  { name: "Accessories", description: "School bags, lunch boxes, and other accessories", icon_name: "bag", display_order: 4 },
  { name: "Dorm & Boarding", description: "Items for boarding school/student accommodation", icon_name: "dorm", display_order: 5 },
  { name: "Electronics", description: "Calculators, laptops, tablets for school", icon_name: "laptop", display_order: 6 },
  { name: "Other", description: "Other school-related items", icon_name: "other", display_order: 7 }
]

main_categories.each do |cat_attrs|
  MainCategory.find_or_create_by!(name: cat_attrs[:name]) do |cat|
    cat.assign_attributes(cat_attrs)
  end
end

# Sub-categories for School Uniforms
uniforms = MainCategory.find_by(name: "School Uniforms")
if uniforms
  [
    { name: "Shirts/Blouses", description: "School shirts and blouses", display_order: 1 },
    { name: "Pants/Trousers", description: "School pants and trousers", display_order: 2 },
    { name: "Skirts", description: "School skirts", display_order: 3 },
    { name: "Blazers/Jackets", description: "School blazers and jackets", display_order: 4 },
    { name: "Ties & Scarves", description: "School ties and scarves", display_order: 5 },
    { name: "Sweaters/Cardigans", description: "School sweaters and cardigans", display_order: 6 },
    { name: "Socks", description: "School socks", display_order: 7 },
    { name: "Shoes", description: "School shoes", display_order: 8 }
  ].each do |sub_attrs|
    uniforms.sub_categories.find_or_create_by!(name: sub_attrs[:name]) do |sub|
      sub.assign_attributes(sub_attrs)
    end
  end
end

puts "Categories created successfully!"