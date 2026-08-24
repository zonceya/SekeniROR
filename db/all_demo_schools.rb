# db/seeds/all_demo_schools.rb
puts "🏫 Seeding All Demo Schools..."
puts "=" * 60

# Define all demo schools with their correct IDs
demo_schools = [
  { id: 14, name: "Mountain Ridge High (Demo)", file: "mountain_ridge_high.rb" },
  { id: 15, name: "Riverside College (Demo)", file: "riverside_college.rb" },
  { id: 16, name: "Ironwood College (Demo)", file: "ironwood_college.rb" },
  { id: 17, name: "St. Elara's College (Demo)", file: "st_elaras_college.rb" },
  { id: 18, name: "Ashridge Primary (Demo)", file: "ashridge_primary.rb" },
  { id: 21, name: "Ubuntu Community School (Demo)", file: "ubuntu_community_school.rb" },
  { id: 22, name: "Willowcrest (Demo)", file: "willowcrest.rb" }
]

demo_schools.each do |school_data|
  school = School.find(school_data[:id])
  count = Item.where(school_id: school.id).count
  puts "  #{school.id}: #{school.name} - #{count} items"
end

# Load each seed file
puts "\n📦 Loading seed files..."
demo_schools.each do |school_data|
  file_path = Rails.root.join("db/seeds/#{school_data[:file]}")
  if File.exist?(file_path)
    load file_path
  else
    puts "⚠️ File not found: #{file_path}"
  end
end

puts "\n✅ All demo schools seeded!"