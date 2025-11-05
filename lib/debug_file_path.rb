# lib/debug_file_path.rb
puts "🔍 DEBUGGING FILE PATH ISSUE"
puts "=" * 50

# Check multiple ways to find the file
paths_to_check = [
  'config/firebase-service-account.json',
  './config/firebase-service-account.json',
  Rails.root.join('config', 'firebase-service-account.json'),
  File.expand_path('config/firebase-service-account.json'),
  "#{Dir.pwd}/config/firebase-service-account.json"
]

puts "Current directory: #{Dir.pwd}"
puts "Rails root: #{Rails.root}"
puts ""

paths_to_check.each do |path|
  exists = File.exist?(path)
  puts "#{exists ? '✅' : '❌'} #{path}"
  if exists
    puts "     Size: #{File.size(path)} bytes"
    puts "     Readable: #{File.readable?(path)}"
  end
end

puts ""
puts "📁 Contents of config directory:"
begin
  Dir.entries('config').each do |file|
    next if file.start_with?('.')
    full_path = "config/#{file}"
    puts "  - #{file} (#{File.size(full_path)} bytes)" if File.exist?(full_path)
  end
rescue => e
  puts "  Error reading directory: #{e.message}"
end

puts ""
puts "🔧 Let's try to read the file directly:"
direct_path = "config/firebase-service-account.json"
if File.exist?(direct_path)
  begin
    content = File.read(direct_path)
    puts "✅ Successfully read file!"
    puts "First 200 chars: #{content[0..200]}"
    
    # Try to parse JSON
    json_data = JSON.parse(content)
    puts "✅ Valid JSON parsed!"
    puts "Project ID: #{json_data['project_id']}"
  rescue JSON::ParserError => e
    puts "❌ JSON Parse Error: #{e.message}"
  rescue => e
    puts "❌ Read Error: #{e.message}"
  end
else
  puts "❌ File not found at direct path"
end