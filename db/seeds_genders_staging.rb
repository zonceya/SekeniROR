# db/seeds_genders_staging.rb
puts "👤 Seeding Genders and Ages for Staging..."
puts "=" * 60

# South African school grades with correct ages
grades_with_ages = [
  { name: "Grade R", age: 5, category: "foundation" },
  { name: "Grade 1", age: 7, category: "foundation" },
  { name: "Grade 2", age: 8, category: "foundation" },
  { name: "Grade 3", age: 9, category: "foundation" },
  { name: "Grade 4", age: 10, category: "intermediate" },
  { name: "Grade 5", age: 11, category: "intermediate" },
  { name: "Grade 6", age: 12, category: "intermediate" },
  { name: "Grade 7", age: 13, category: "intermediate" },
  { name: "Grade 8", age: 14, category: "senior" },
  { name: "Grade 9", age: 15, category: "senior" },
  { name: "Grade 10", age: 16, category: "fet" },
  { name: "Grade 11", age: 17, category: "fet" },
  { name: "Grade 12", age: 18, category: "fet" },
  { name: "Matric", age: 19, category: "fet" }
]

puts "📦 Creating #{grades_with_ages.count} grade-based genders..."

grades_with_ages.each do |grade|
  gender = Gender.find_or_create_by(name: grade[:name]) do |g|
    g.exact_age = grade[:age]
    g.category = grade[:category]
    g.display_name = grade[:name]
    g.gender_group = "all"
  end
  puts "✅ #{gender.name}: Age #{gender.exact_age}"
end

# Gender-specific grades
gender_specific = [
  { name: "Pre-Primary Boys", age: 5, category: "pre-primary", group: "male" },
  { name: "Pre-Primary Girls", age: 5, category: "pre-primary", group: "female" },
  { name: "Grade 1 Boys", age: 7, category: "primary", group: "male" },
  { name: "Grade 1 Girls", age: 7, category: "primary", group: "female" },
  { name: "Grade 2 Boys", age: 8, category: "primary", group: "male" },
  { name: "Grade 2 Girls", age: 8, category: "primary", group: "female" },
  { name: "Grade 3 Boys", age: 9, category: "primary", group: "male" },
  { name: "Grade 3 Girls", age: 9, category: "primary", group: "female" },
  { name: "Grade 4 Boys", age: 10, category: "primary", group: "male" },
  { name: "Grade 4 Girls", age: 10, category: "primary", group: "female" },
  { name: "Grade 5 Boys", age: 11, category: "primary", group: "male" },
  { name: "Grade 5 Girls", age: 11, category: "primary", group: "female" },
  { name: "Grade 6 Boys", age: 12, category: "primary", group: "male" },
  { name: "Grade 6 Girls", age: 12, category: "primary", group: "female" },
  { name: "Grade 7 Boys", age: 13, category: "primary", group: "male" },
  { name: "Grade 7 Girls", age: 13, category: "primary", group: "female" },
  { name: "Grade 8 Boys", age: 14, category: "high", group: "male" },
  { name: "Grade 8 Girls", age: 14, category: "high", group: "female" },
  { name: "Grade 9 Boys", age: 15, category: "high", group: "male" },
  { name: "Grade 9 Girls", age: 15, category: "high", group: "female" },
  { name: "Grade 10 Boys", age: 16, category: "high", group: "male" },
  { name: "Grade 10 Girls", age: 16, category: "high", group: "female" },
  { name: "Grade 11 Boys", age: 17, category: "high", group: "male" },
  { name: "Grade 11 Girls", age: 17, category: "high", group: "female" },
  { name: "Grade 12 Boys", age: 18, category: "high", group: "male" },
  { name: "Grade 12 Girls", age: 18, category: "high", group: "female" }
]

puts "\n📦 Creating #{gender_specific.count} gender-specific grades..."

gender_specific.each do |g|
  gender = Gender.find_or_create_by(name: g[:name]) do |gen|
    gen.exact_age = g[:age]
    gen.category = g[:category]
    gen.display_name = g[:name]
    gen.gender_group = g[:group]
  end
  puts "✅ #{gender.name}: Age #{gender.exact_age} (#{gender.gender_group})"
end

# Basic genders without ages
basic_genders = [
  { name: "Boys", group: "boys" },
  { name: "Girls", group: "girls" },
  { name: "Unisex", group: "unisex" }
]

puts "\n📦 Creating basic genders..."

basic_genders.each do |g|
  gender = Gender.find_or_create_by(name: g[:name]) do |gen|
    gen.category = "standard"
    gen.display_name = g[:name]
    gen.gender_group = g[:group]
  end
  puts "✅ #{gender.name}"
end

puts ""
puts "=" * 60
puts "📊 Summary:"
puts "  📚 Total Genders: #{Gender.count}"
puts "  👤 With Ages: #{Gender.where.not(exact_age: nil).count}"
puts "  👤 Without Ages: #{Gender.where(exact_age: nil).count}"