# lib/tasks/system_schools.rake

namespace :system_schools do
  desc "Seed all system schools with complete data"
  task seed_all: :environment do
    puts "🚀 Seeding all system schools..."
    puts "=" * 50
    
    School::SYSTEM_SCHOOL_NAMES.each do |school_name|
      puts "\n📚 Processing: #{school_name}"
      service = SeedSystemSchoolService.new(school_name, skip_existing: true)
      service.call
    end
    
    puts "\n" + "=" * 50
    puts "🎉 All system schools seeded successfully!"
    
    # Show summary
    School::SYSTEM_SCHOOL_NAMES.each do |name|
      school = School.find_by(name: name)
      if school
        puts "  #{name}: #{school.items.count} items"
      else
        puts "  #{name}: NOT FOUND"
      end
    end
  end

  desc "Seed a specific system school"
  task :seed_one, [:school_name] => :environment do |t, args|
    school_name = args[:school_name]
    
    if school_name.blank?
      puts "❌ Please provide school_name: rake system_schools:seed_one[Ironwood-College]"
      exit 1
    end
    
    puts "🚀 Seeding: #{school_name}"
    service = SeedSystemSchoolService.new(school_name)
    result = service.call
    
    if result
      school = School.find_by(name: school_name)
      puts "✅ #{school_name} seeded successfully with #{school&.items&.count || 0} items"
    else
      puts "❌ Failed to seed #{school_name}"
    end
  end

  desc "Add a new system school"
  task :add_school, [:school_name] => :environment do |t, args|
    school_name = args[:school_name]
    
    if school_name.blank?
      puts "❌ Please provide school_name: rake system_schools:add_school[new-school]"
      exit 1
    end
    
    puts "🚀 Adding new system school: #{school_name}"
    
    # Add to School model constant
    # This requires a code change, but we'll display instructions
    puts "📝 To add #{school_name} permanently:"
    puts "  1. Add '#{school_name}' to School::SYSTEM_SCHOOL_NAMES constant"
    puts "  2. Run: rake system_schools:seed_one[#{school_name}]"
    puts ""
    puts "⏳ Creating temporary school and seeding..."
    
    # Create and seed the school
    service = SeedSystemSchoolService.new(school_name)
    result = service.call
    
    if result
      school = School.find_by(name: school_name)
      puts "✅ #{school_name} created and seeded with #{school&.items&.count || 0} items"
      puts ""
      puts "📝 Don't forget to add '#{school_name}' to School::SYSTEM_SCHOOL_NAMES!"
    else
      puts "❌ Failed to create #{school_name}"
    end
  end

  desc "List all system schools and their item counts"
  task list: :environment do
    puts "📚 System Schools Summary"
    puts "=" * 50
    
    School::SYSTEM_SCHOOL_NAMES.each do |name|
      school = School.find_by(name: name)
      if school
        items_count = school.items.where(deleted: false, status: 'active').count
        categories = school.items.joins(:main_category)
                               .distinct
                               .pluck('main_categories.name')
        puts "  #{name}:"
        puts "    Items: #{items_count}"
        puts "    Categories: #{categories.join(', ')}" if categories.any?
      else
        puts "  #{name}: ❌ NOT FOUND"
      end
    end
  end

  desc "Refresh all system schools data (update prices, dates, etc.)"
  task refresh: :environment do
    puts "🔄 Refreshing system schools data..."
    
    School::SYSTEM_SCHOOL_NAMES.each do |name|
      school = School.find_by(name: name)
      next unless school
      
      puts "  📚 Refreshing #{name}..."
      
      # Update created_at to be more recent
      school.items.where("created_at < ?", 30.days.ago).each do |item|
        item.update!(
          created_at: Time.current - rand(0..30).days,
          view_count: rand(10..100)
        )
      end
      
      # Update trending in Redis
      service = SeedSystemSchoolService.new(name)
      service.send(:update_trending_in_redis, school)
      
      puts "    ✅ #{name} refreshed"
    end
    
    puts "🎉 All system schools refreshed!"
  end

  desc "Delete all items from system schools"
  task clean: :environment do
    puts "🧹 Cleaning system schools items..."
    
    School::SYSTEM_SCHOOL_NAMES.each do |name|
      school = School.find_by(name: name)
      next unless school
      
      count = school.items.count
      school.items.destroy_all
      puts "  🗑️  Removed #{count} items from #{name}"
    end
    
    puts "✅ All system school items cleaned!"
  end

  desc "Dry run - show what would be seeded"
  task :dry_run, [:school_name] => :environment do |t, args|
    school_name = args[:school_name] || School::SYSTEM_SCHOOL_NAMES.first
    
    puts "🔍 DRY RUN - Would seed: #{school_name}"
    service = SeedSystemSchoolService.new(school_name, dry_run: true)
    service.call
    puts "✅ Dry run complete - no changes made"
  end
end