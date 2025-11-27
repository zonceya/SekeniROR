require 'redis'

redis = Redis.new(host: 'localhost', port: 6379)

# Test connection
redis.set("mykey", "Hello, Redis!")
puts redis.get("mykey")  # Should print "Hello, Redis!"
