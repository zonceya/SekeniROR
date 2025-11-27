# config/initializers/sidekiq.rb
require 'sidekiq'
require 'sidekiq-cron'

Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://localhost:6379/0' }

  # Hardcode schedule to ensure it loads
  schedule = {
    'expire_holds' => {
      'class' => 'ExpireHoldsJob',
      'cron'  => '*/1 * * * *', # Every minute
      'queue' => 'critical',
      'description' => 'Auto-expire holds'
    }
  }

  # Clear existing jobs and reload
  Sidekiq::Cron::Job.destroy_all!
  if Sidekiq::Cron::Job.load_from_hash(schedule)
    Rails.logger.info "✔ Successfully loaded cron jobs: #{Sidekiq::Cron::Job.all.map(&:name)}"
  else
    Rails.logger.error "✖ Failed to load cron jobs!"
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://localhost:6379/0' }
end