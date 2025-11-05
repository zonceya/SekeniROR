# lib/debug_enum_method.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Debugging enum method..."
puts "=" * 30

puts "Rails version: #{Rails.version}"
puts "ActiveRecord version: #{ActiveRecord::VERSION::STRING}"

# Check where the enum method is defined
enum_method = ActiveRecord::Base.method(:enum)
puts "Enum method source location: #{enum_method.source_location}"

# Check the method parameters
begin
  parameters = enum_method.parameters
  puts "Enum method parameters: #{parameters.inspect}"
rescue => e
  puts "Cannot get parameters: #{e.message}"
end

# Try to call enum with different syntax
begin
  puts "Testing enum call..."
  class TestModel < ActiveRecord::Base
    self.table_name = 'flagged_payments'
    enum status: { test1: 'test1', test2: 'test2' }
  end
  puts "✅ Direct enum call works"
rescue => e
  puts "❌ Direct enum call failed: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(3)
end