require 'dotenv'
Dotenv.load

puts 'Environment variables:'
ENV.each do |key, value|
  puts \"\#{key}: \#{value}\" if key.start_with?('GOOGLE_')
end
