# lib/check_gems.rb
puts "Googleauth version: #{Gem.loaded_specs['googleauth']&.version}"
puts "Available methods on ServiceAccountCredentials:"
puts Google::Auth::ServiceAccountCredentials.methods.sort