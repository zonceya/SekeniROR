puts "Seeding Main Categories and Sub Categories..."

# First, clear existing data (optional, comment out if you want to keep existing data)
# MainCategory.destroy_all
# SubCategory.destroy_all

# 1. School Uniforms
school_uniforms = MainCategory.find_or_create_by!(
  name: "School Uniforms",
  description: "Official school uniforms for all grades",
  icon_name: "school",
  is_active: true,
  display_order: 1
)

SubCategory.find_or_create_by!(
  name: "Shirts & Blouses",
  description: "School shirts and blouses",
  main_category: school_uniforms,
  is_active: true,
  display_order: 1
)

SubCategory.find_or_create_by!(
  name: "Pants & Trousers",
  description: "School pants and trousers",
  main_category: school_uniforms,
  is_active: true,
  display_order: 2
)

SubCategory.find_or_create_by!(
  name: "Skirts",
  description: "School skirts",
  main_category: school_uniforms,
  is_active: true,
  display_order: 3
)

SubCategory.find_or_create_by!(
  name: "Blazers & Jackets",
  description: "School blazers and jackets",
  main_category: school_uniforms,
  is_active: true,
  display_order: 4
)

SubCategory.find_or_create_by!(
  name: "Ties",
  description: "School ties",
  main_category: school_uniforms,
  is_active: true,
  display_order: 5
)

SubCategory.find_or_create_by!(
  name: "Sweaters & Cardigans",
  description: "School sweaters and cardigans",
  main_category: school_uniforms,
  is_active: true,
  display_order: 6
)

# 2. Books & Stationery
books_stationery = MainCategory.find_or_create_by!(
  name: "Books & Stationery",
  description: "Textbooks, notebooks, and writing materials",
  icon_name: "book",
  is_active: true,
  display_order: 2
)

SubCategory.find_or_create_by!(
  name: "Textbooks",
  description: "School textbooks",
  main_category: books_stationery,
  is_active: true,
  display_order: 1
)

SubCategory.find_or_create_by!(
  name: "Workbooks",
  description: "Exercise and workbooks",
  main_category: books_stationery,
  is_active: true,
  display_order: 2
)

SubCategory.find_or_create_by!(
  name: "Notebooks",
  description: "Writing notebooks",
  main_category: books_stationery,
  is_active: true,
  display_order: 3
)

SubCategory.find_or_create_by!(
  name: "Stationery Sets",
  description: "Pens, pencils, rulers, etc.",
  main_category: books_stationery,
  is_active: true,
  display_order: 4
)

# 3. Sports Gear
sports_gear = MainCategory.find_or_create_by!(
  name: "Sports Gear",
  description: "Sports equipment and uniforms",
  icon_name: "sports_soccer",
  is_active: true,
  display_order: 3
)

SubCategory.find_or_create_by!(
  name: "Sports Uniforms",
  description: "Official sports uniforms",
  main_category: sports_gear,
  is_active: true,
  display_order: 1
)

SubCategory.find_or_create_by!(
  name: "Sports Shoes",
  description: "Athletic footwear",
  main_category: sports_gear,
  is_active: true,
  display_order: 2
)

SubCategory.find_or_create_by!(
  name: "Sports Equipment",
  description: "Balls, rackets, etc.",
  main_category: sports_gear,
  is_active: true,
  display_order: 3
)

SubCategory.find_or_create_by!(
  name: "Training Gear",
  description: "Training clothes and accessories",
  main_category: sports_gear,
  is_active: true,
  display_order: 4
)

# 4. Accessories
accessories = MainCategory.find_or_create_by!(
  name: "Accessories",
  description: "School bags and accessories",
  icon_name: "backpack",
  is_active: true,
  display_order: 4
)

SubCategory.find_or_create_by!(
  name: "School Bags",
  description: "Backpacks and school bags",
  main_category: accessories,
  is_active: true,
  display_order: 1
)

SubCategory.find_or_create_by!(
  name: "Lunch Boxes",
  description: "Food containers",
  main_category: accessories,
  is_active: true,
  display_order: 2
)

SubCategory.find_or_create_by!(
  name: "Water Bottles",
  description: "Drink containers",
  main_category: accessories,
  is_active: true,
  display_order: 3
)

SubCategory.find_or_create_by!(
  name: "Other Accessories",
  description: "Other school accessories",
  main_category: accessories,
  is_active: true,
  display_order: 4
)

# 5. Electronics (optional addition)
electronics = MainCategory.find_or_create_by!(
  name: "Electronics",
  description: "School-related electronics",
  icon_name: "computer",
  is_active: true,
  display_order: 5
)

SubCategory.find_or_create_by!(
  name: "Calculators",
  description: "Scientific calculators",
  main_category: electronics,
  is_active: true,
  display_order: 1
)

SubCategory.find_or_create_by!(
  name: "Tablets & Laptops",
  description: "Learning devices",
  main_category: electronics,
  is_active: true,
  display_order: 2
)

SubCategory.find_or_create_by!(
  name: "Headphones",
  description: "Audio accessories",
  main_category: electronics,
  is_active: true,
  display_order: 3
)

puts "Seeding complete!"
puts "Created #{MainCategory.count} main categories"
puts "Created #{SubCategory.count} sub categories"