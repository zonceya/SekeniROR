source "https://rubygems.org"

gem "rails", "~> 8.0.1"
gem "propshaft"
gem 'pg', '>= 1.6.2'
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"

# Windows does not include zoneinfo files
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem 'rack-cors'
gem "kamal", require: false
gem "thruster", require: false

# Background jobs and scheduling
gem 'rufus-scheduler'
gem 'whenever', require: false
gem 'sidekiq'
gem 'sidekiq-cron'

# Caching and auth
gem "redis", "~> 5.4"
gem 'bcrypt', '~> 3.1.7'
gem 'jwt'
gem 'faraday', '~> 2.7'
gem 'openssl', '~> 3.0'
# Serializers
gem 'jsonapi-serializer'
gem 'active_model_serializers'

# Pagination
gem 'kaminari'

# Google APIs
gem 'google-apis-gmail_v1', '~> 0.45.0'
gem 'googleauth'

# Utilities
gem 'fileutils'
gem "fiddle" # to silence Ruby 3.5 warning about fiddle
gem 'fcm'

# Environment variables (MUST be at the top of groups)
gem "dotenv-rails", "~> 3.1"
gem 'firebase-admin-sdk'
# AWS/R2 for file uploads
gem 'aws-sdk-s3', '~> 1.0'
gem 'down', '~> 5.0'
gem 'mini_magick'

# Email handling (required for SMTP)
gem 'net-smtp', require: false
gem 'net-pop', require: false
gem 'net-imap', require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem 'rspec-rails'
  gem 'factory_bot_rails'
end

group :development do
  gem "web-console"
  gem 'letter_opener', '~> 1.8'  # Opens emails in browser for testing
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end