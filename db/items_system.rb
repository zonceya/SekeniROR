# db/seeds/items_system.rb

puts "Seeding item system..."

# 1. Ensure we have categories first
puts "Creating school categories..."

# Main Categories
main_categories = [
  { name: "School Uniforms", description: "Official school uniforms", slug: "school-uniforms", icon: "👔" },
  { name: "Books & Stationery", description: "Textbooks and writing materials", slug: "books-stationery", icon: "📚" },
  { name: "Sports Gear", description: "Sports equipment and uniforms", slug: "sports-gear", icon: "⚽" },
  { name: "Accessories", description: "School bags and accessories", slug: "accessories", icon: "🎒" }
]

main_categories.each do |attrs|
  Category.find_or_create_by!(name: attrs[:name]) do |cat|
    cat.assign_attributes(attrs)
  end
end

# Sub-categories for School Uniforms
uniforms = Category.find_by(name: "School Uniforms")
if uniforms
  [
    { name: "Shirts/Blouses", parent_id: uniforms.id, slug: "shirts-blouses" },
    { name: "Pants/Trousers", parent_id: uniforms.id, slug: "pants-trousers" },
    { name: "Skirts", parent_id: uniforms.id, slug: "skirts" },
    { name: "Blazers/Jackets", parent_id: uniforms.id, slug: "blazers-jackets" },
    { name: "Ties", parent_id: uniforms.id, slug: "ties" },
    { name: "Sweaters", parent_id: uniforms.id, slug: "sweaters" },
    { name: "Socks", parent_id: uniforms.id, slug: "socks" },
    { name: "Shoes", parent_id: uniforms.id, slug: "shoes" }
  ].each do |sub_attrs|
    Category.find_or_create_by!(name: sub_attrs[:name]) do |cat|
      cat.assign_attributes(sub_attrs)
    end
  end
end

# 2. Create sample schools
puts "Creating schools..."
schools = [
  { name: "University of Cape Town", province_id: 9, school_type: "university" },
  { name: "University of the Witwatersrand", province_id: 3, school_type: "university" },
  { name: "Stellenbosch University", province_id: 9, school_type: "university" }
]

schools.each do |attrs|
  School.find_or_create_by!(name: attrs[:name]) do |school|
    school.assign_attributes(attrs)
  end
end

# 3. Create sample items with variants
puts "Creating sample items with variants..."

# Get references
shirts_category = Category.find_by(name: "Shirts/Blouses")
uct = School.find_by(name: "University of Cape Town")
brand_nike = Brand.find_or_create_by!(name: "Nike")
brand_cotton = Brand.find_or_create_by!(name: "Cotton King")

# Sample item: School Shirt
if shirts_category && uct
  puts "Creating school shirt item..."
  
  shirt_item = Item.create!(
    name: "UCT School Shirt",
    description: "Official UCT white school shirt, 100% cotton",
    category_id: shirts_category.id,
    school_id: uct.id,
    brand_id: brand_cotton.id,
    status: 'active'
  )
  
  # Create variants with different sizes
  sizes = ItemSize.where(name: ['S', 'M', 'L', 'XL'])
  colors = ItemColor.where(name: ['White', 'Blue'])
  conditions = ItemCondition.where(name: ['New', 'Used - Like New'])
  
  # Create variant combinations
  variants_created = 0
  sizes.each do |size|
    colors.each do |color|
      conditions.each do |condition|
        ItemVariant.create!(
          item: shirt_item,
          size: size,
          color: color,
          condition: condition,
          sku: "UCT-SHIRT-#{size.name}-#{color.name}-#{condition.name.first(3).upcase}",
          price: condition.name == 'New' ? 45.00 : 25.00,
          quantity: condition.name == 'New' ? 10 : 5,
          reserved: 0,
          is_active: true
        )
        variants_created += 1
      end
    end
  end
  
  puts "  Created #{variants_created} variants for school shirt"
end

# Sample item: Sports Shoes
sports_shoes_category = Category.find_by(name: "Shoes")&.parent&.name == "Sports Gear" ? Category.find_by(name: "Shoes") : nil

if sports_shoes_category && uct
  puts "Creating sports shoes item..."
  
  shoes_item = Item.create!(
    name: "Nike Soccer Cleats",
    description: "Nike soccer cleats for school sports",
    category_id: sports_shoes_category.id,
    school_id: uct.id,
    brand_id: brand_nike.id,
    status: 'active'
  )
  
  # Shoe sizes (different from clothing sizes)
  shoe_sizes = [7, 8, 9, 10, 11].map do |size_num|
    ItemSize.find_or_create_by!(name: size_num.to_s)
  end
  
  colors = ItemColor.where(name: ['Black', 'White', 'Red'])
  conditions = ItemCondition.where(name: ['New', 'Used - Good'])
  
  shoe_variants = 0
  shoe_sizes.each do |size|
    colors.each do |color|
      conditions.each do |condition|
        ItemVariant.create!(
          item: shoes_item,
          size: size,
          color: color,
          condition: condition,
          sku: "NIKE-SHOE-#{size.name}-#{color.name}-#{condition.name.first(3).upcase}",
          price: condition.name == 'New' ? 120.00 : 65.00,
          quantity: condition.name == 'New' ? 5 : 3,
          reserved: 0,
          is_active: true
        )
        shoe_variants += 1
      end
    end
  end
  
  puts "  Created #{shoe_variants} variants for sports shoes"
end

# Sample item: Textbook
textbooks_category = Category.find_by(name: "Textbooks") || 
  Category.find_by(name: "Books & Stationery")&.children&.find_by(name: "Textbooks")

if textbooks_category && uct
  puts "Creating textbook item..."
  
  textbook_item = Item.create!(
    name: "Mathematics Textbook Grade 10",
    description: "Official curriculum mathematics textbook",
    category_id: textbooks_category.id,
    school_id: uct.id,
    brand_id: Brand.find_or_create_by!(name: "Cambridge"),
    status: 'active'
  )
  
  # Books typically don't have sizes/colors, just condition
  conditions = ItemCondition.all
  
  book_variants = 0
  conditions.each do |condition|
    ItemVariant.create!(
      item: textbook_item,
      condition: condition,
      sku: "MATH-G10-#{condition.name.first(3).upcase}",
      price: condition.name == 'New' ? 85.00 : 40.00,
      quantity: condition.name == 'New' ? 8 : 6,
      reserved: 0,
      is_active: true
    )
    book_variants += 1
  end
  
  puts "  Created #{book_variants} variants for textbook"
end

puts "Seeding complete!"
puts "Summary:"
puts "- #{Category.count} categories"
puts "- #{Item.count} items"
puts "- #{ItemVariant.count} variants"
puts "- #{School.count} schools"