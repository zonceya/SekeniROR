# lib/check_gmail_structure.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Checking Gmail services structure..."
puts "=" * 50

# Check if file exists
gmail_path = Rails.root.join('app', 'services', 'gmail', 'bank_email_parser.rb')
if File.exist?(gmail_path)
  puts "✅ File exists: app/services/gmail/bank_email_parser.rb"
  
  # Read the first few lines to check namespace
  first_lines = File.readlines(gmail_path).first(5).join
  if first_lines.include?('module Gmail')
    puts "✅ File uses Gmail module namespace"
    puts "Use: Gmail::BankEmailParser.parse(email)"
  else
    puts "❌ File does not use Gmail namespace"
    puts "Use: BankEmailParser.parse(email)"
  end
else
  puts "❌ File not found: app/services/gmail/bank_email_parser.rb"
  puts "Available services:"
  Dir[Rails.root.join('app', 'services', '**', '*.rb')].each do |file|
    puts "  - #{file.relative_path_from(Rails.root)}"
  end
end