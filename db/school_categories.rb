# db/seeds.rb or create db/seeds/school_categories.rb
# School-Focused Main Categories
MainCategory.create!([
  {
    name: "School Uniforms",
    description: "Official school uniforms and attire",
    icon_name: "uniform",
    display_order: 1,
    is_active: true
  },
  {
    name: "Books & Stationery",
    description: "Textbooks, workbooks, and writing materials",
    icon_name: "books",
    display_order: 2,
    is_active: true
  },
  {
    name: "Sports Gear",
    description: "Sports equipment and athletic wear",
    icon_name: "sports",
    display_order: 3,
    is_active: true
  },
  {
    name: "Accessories",
    description: "School bags, lunch boxes, and other accessories",
    icon_name: "bag",
    display_order: 4,
    is_active: true
  },
  {
    name: "Dorm & Boarding",
    description: "Items for boarding school/student accommodation",
    icon_name: "dorm",
    display_order: 5,
    is_active: true
  },
  {
    name: "Electronics",
    description: "Calculators, laptops, tablets for school",
    icon_name: "laptop",
    display_order: 6,
    is_active: true
  },
  {
    name: "Other",
    description: "Other school-related items",
    icon_name: "other",
    display_order: 7,
    is_active: true
  }
])

# Sub-categories for School Uniforms
uniforms = MainCategory.find_by(name: "School Uniforms")
SubCategory.create!([
  { main_category: uniforms, name: "Shirts/Blouses", display_order: 1 },
  { main_category: uniforms, name: "Pants/Trousers", display_order: 2 },
  { main_category: uniforms, name: "Skirts", display_order: 3 },
  { main_category: uniforms, name: "Blazers/Jackets", display_order: 4 },
  { main_category: uniforms, name: "Ties & Scarves", display_order: 5 },
  { main_category: uniforms, name: "Sweaters/Cardigans", display_order: 6 },
  { main_category: uniforms, name: "Socks", display_order: 7 },
  { main_category: uniforms, name: "Shoes", display_order: 8 }
])

# Sub-categories for Books & Stationery
books = MainCategory.find_by(name: "Books & Stationery")
SubCategory.create!([
  { main_category: books, name: "Textbooks", display_order: 1 },
  { main_category: books, name: "Workbooks", display_order: 2 },
  { main_category: books, name: "Study Guides", display_order: 3 },
  { main_category: books, name: "Pens & Pencils", display_order: 4 },
  { main_category: books, name: "Notebooks", display_order: 5 },
  { main_category: books, name: "Art Supplies", display_order: 6 }
])

# Sub-categories for Sports Gear
sports = MainCategory.find_by(name: "Sports Gear")
SubCategory.create!([
  { main_category: sports, name: "Sports Uniforms", display_order: 1 },
  { main_category: sports, name: "Sports Shoes", display_order: 2 },
  { main_category: sports, name: "Equipment", display_order: 3 },
  { main_category: sports, name: "Protective Gear", display_order: 4 }
])

# Update existing item_types with main_category_id
ItemType.find_by(name: "Shirt")&.update(main_category_id: uniforms.id)
ItemType.find_by(name: "Pants")&.update(main_category_id: uniforms.id)
ItemType.find_by(name: "Skirt")&.update(main_category_id: uniforms.id)
ItemType.find_by(name: "Blazer")&.update(main_category_id: uniforms.id)
ItemType.find_by(name: "Pens")&.update(main_category_id: books.id)
ItemType.find_by(name: "Notebooks")&.update(main_category_id: books.id)
ItemType.find_by(name: "Textbook")&.update(main_category_id: books.id)
ItemType.find_by(name: "Tracksuit")&.update(main_category_id: sports.id)
ItemType.find_by(name: "Soccer Shoes")&.update(main_category_id: sports.id)