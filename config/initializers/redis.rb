# config/initializers/redis.rb
require 'redis'

# Create a global variable that will be available throughout your Rails app
$redis = Redis.new(host: 'localhost', port: 6379)

# Test connection (this will show in your Rails console/ server logs)
begin
  $redis.set("connection_test", "working")
  puts "✓ Redis connected! Test value: #{$redis.get("connection_test")}"
rescue => e
  puts "✗ Redis connection failed: #{e.message}"
end
$redis = Redis.new(
  url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'),
  db: 1  # Matches your cable.yml
)