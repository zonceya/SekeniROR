# app/services/seed_system_school_service.rb

class SeedSystemSchoolService
  # ================================================================
  # CATEGORY CONFIGURATION
  # ================================================================
  
  CATEGORY_CONFIG = {
    'uniform' => {
      main_category: 'Uniform',
      sub_categories: ['School Uniform', 'Formal Wear', 'Ties & Accessories'],
      item_names: ['Blazer', 'Tie', 'Shirt', 'Trousers', 'Skirt', 'Jersey', 'Cap', 'Scarf', 'Socks', 'Shoes'],
      price_range: (50..450),
      count: 8..10
    },
    'sport' => {
      main_category: 'Sport',
      sub_categories: ['Team Sports', 'Athletics', 'Sports Gear'],
      item_names: ['Rugby Jersey', 'Soccer Kit', 'Netball Dress', 'Sports Bag', 'Water Bottle', 'Sports Socks', 'Training Pants', 'Sports Hoodie'],
      price_range: (45..350),
      count: 6..8
    },
    'accessories' => {
      main_category: 'Accessories',
      sub_categories: ['Bags', 'Shoes', 'Belts', 'Jewelry'],
      item_names: ['School Bag', 'Belt', 'Tie Pin', 'Lanyard', 'Keychain', 'Umbrella', 'Hat'],
      price_range: (25..200),
      count: 6..8
    },
    'stationery' => {
      main_category: 'Stationery',
      sub_categories: ['Books', 'Writing', 'Calculators', 'Art Supplies'],
      item_names: ['Exercise Book', 'Calculator', 'Pen Set', 'Pencil Case', 'Ruler Set', 'Geometry Set', 'Diary'],
      price_range: (15..150),
      count: 5..7
    },
    'general' => {
      main_category: nil,  # Will use existing or create 'General'
      sub_categories: ['Miscellaneous', 'School Supplies'],
      item_names: ['Water Bottle', 'Lunch Bag', 'Badge', 'Sticker Set'],
      price_range: (10..100),
      count: 3..5
    }
  }

  # ================================================================
  # INITIALIZATION
  # ================================================================
  
  def initialize(school_name, options = {})
    @school_name = school_name
    @skip_existing = options[:skip_existing] || false
    @dry_run = options[:dry_run] || false
  end

  # ================================================================
  # MAIN ENTRY POINT
  # ================================================================
  
  def call
    puts "🌱 Seeding system school: #{@school_name}"
    
    # Step 1: Find or create the school
    school = find_or_create_school
    return false unless school
    
    # Step 2: Skip if items already exist and skip_existing is true
    if @skip_existing && school.items.exists?
      puts "  ⏭️  Skipping #{@school_name} - items already exist"
      return true
    end
    
    # Step 3: Seed all categories
    seed_all_categories(school)
    
    # Step 4: Add artificial view counts
    add_artificial_views(school)
    
    # Step 5: Update trending in Redis
    update_trending_in_redis(school)
    
    puts "  ✅ Successfully seeded #{@school_name} with #{school.items.count} items"
    true
  end

  # ================================================================
  # SCHOOL MANAGEMENT
  # ================================================================
  
  private

  def find_or_create_school
    school = School.find_by(name: @school_name)
    
    if school
      puts "  📍 Found existing school: #{@school_name}"
      return school
    end
    
    if @dry_run
      puts "  🔍 DRY RUN: Would create #{@school_name}"
      return nil
    end
    
    puts "  🏫 Creating new school: #{@school_name}"
    
    School.create!(
      name: @school_name,
      emis: "DEMO#{rand(10000..99999)}",
      province_id: Province.first&.id || 1,
      location_id: Location.first&.id,
      created_at: Time.current,
      updated_at: Time.current
    )
  rescue => e
    puts "  ❌ Failed to create school: #{e.message}"
    nil
  end

  # ================================================================
  # CATEGORY SEEDING
  # ================================================================
  
  def seed_all_categories(school)
    CATEGORY_CONFIG.each do |category_key, config|
      puts "  📂 Seeding #{category_key}..."
      seed_category(school, category_key, config)
    end
  end

  def seed_category(school, category_key, config)
    # Get or create main category
    main_category = find_or_create_main_category(config[:main_category] || category_key.capitalize)
    
    # Get or create sub-categories
    sub_categories = config[:sub_categories].map do |sub_name|
      find_or_create_sub_category(sub_name, main_category.id)
    end
    
    # Determine how many items to create
    count_range = config[:count]
    item_count = rand(count_range)
    
    # Create items
    item_count.times do |i|
      create_item_for_school(school, main_category, sub_categories, config, i)
    end
  end

  def find_or_create_main_category(name)
    MainCategory.find_or_create_by!(name: name) do |cat|
      cat.is_active = true
      cat.display_order = MainCategory.count + 1
    end
  end

  def find_or_create_sub_category(name, main_category_id)
    SubCategory.find_or_create_by!(
      name: name,
      main_category_id: main_category_id
    ) do |sub|
      sub.is_active = true
      sub.display_order = SubCategory.where(main_category_id: main_category_id).count + 1
    end
  end

  # ================================================================
  # ITEM CREATION
  # ================================================================
  
  def create_item_for_school(school, main_category, sub_categories, config, index)
    # Skip if dry run
    return if @dry_run
    
    # Generate item data
    item_name = generate_item_name(school, config[:item_names], index)
    price = rand(config[:price_range])
    created_at = Time.current - rand(0..30).days
    sub_category = sub_categories.sample
    
    # Check if item already exists (by name and school)
    existing = school.items.find_by(name: item_name)
    if existing
      puts "    ⏭️  Item already exists: #{item_name}"
      return existing
    end
    
    # Create the item
    item = Item.create!(
      name: item_name,
      description: generate_description(school.name, main_category.name, item_name),
      price: price,
      main_category_id: main_category.id,
      sub_category_id: sub_category.id,
      school_id: school.id,
      brand_id: Brand.first&.id,
      status: 1,  # active
      deleted: false,
      created_at: created_at,
      updated_at: created_at,
      view_count: rand(5..50),
      total_quantity: rand(5..20),
      item_condition_id: ItemCondition.first&.id || 1
    )
    
    # Create a variant for the item
    create_item_variant(item, price)
    
    puts "    ✅ Created: #{item.name} (#{item.price})"
    item
  rescue => e
    puts "    ❌ Failed to create item: #{e.message}"
    nil
  end

  def generate_item_name(school, names, index)
    base_name = names[index % names.length]
    "#{school.name} #{base_name}"
  end

  def generate_description(school_name, category, item_name)
    "Official #{school_name} #{category.downcase} item - #{item_name}. High quality school merchandise."
  end

  def create_item_variant(item, price)
    ItemVariant.create!(
      item_id: item.id,
      size_id: ItemSize.first&.id || 1,
      color_id: ItemColor.first&.id || 1,
      condition_id: ItemCondition.first&.id || 1,
      price: price,
      quantity: rand(5..20),
      is_active: true,
      sku: "SKU-#{item.id}-#{rand(1000..9999)}"
    )
  rescue => e
    puts "    ⚠️  Failed to create variant: #{e.message}"
  end

  # ================================================================
  # ARTIFICIAL DATA
  # ================================================================
  
  def add_artificial_views(school)
    school.items.each do |item|
      # Add random view count if it's too low
      if item.view_count.to_i < 10
        item.update!(view_count: rand(10..100))
      end
    end
  end

  def update_trending_in_redis(school)
    return unless defined?($redis) && $redis
    
    school.items.each do |item|
      # Add to trending sets
      $redis.zadd("school:#{school.id}:trending:today", item.view_count.to_i + rand(0..20), item.id)
      $redis.zadd("school:#{school.id}:trending:week", item.view_count.to_i + rand(0..50), item.id)
      $redis.zadd("school:#{school.id}:trending:month", item.view_count.to_i + rand(0..100), item.id)
    end
  rescue => e
    puts "    ⚠️  Redis update failed (non-fatal): #{e.message}"
  end
end