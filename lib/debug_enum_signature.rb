# lib/debug_enum_signature.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Debugging enum method signature..."
puts "=" * 40

# Get the actual method object
enum_method = ActiveRecord::Base.method(:enum)

# Check the exact parameters
puts "Method parameters: #{enum_method.parameters.inspect}"

# Check the method source
begin
  source = enum_method.source
  puts "Method source (first 200 chars): #{source[0..200]}..."
rescue => e
  puts "Cannot get source: #{e.message}"
end

# Test different calling patterns
puts "\nTesting different enum calls:"

begin
  class Test1 < ActiveRecord::Base
    self.table_name = 'flagged_payments'
    enum(:status, [:active, :inactive])
  end
  puts "✅ enum(:name, array) works"
rescue => e
  puts "❌ enum(:name, array) failed: #{e.message}"
end

begin
  class Test2 < ActiveRecord::Base
    self.table_name = 'flagged_payments'
    enum(:status, { active: 'active', inactive: 'inactive' })
  end
  puts "✅ enum(:name, hash) works"
rescue => e
  puts "❌ enum(:name, hash) failed: #{e.message}"
end

begin
  class Test3 < ActiveRecord::Base
    self.table_name = 'flagged_payments'
    enum status: { active: 'active', inactive: 'inactive' }
  end
  puts "✅ enum status: hash works"
rescue => e
  puts "❌ enum status: hash failed: #{e.message}"
end