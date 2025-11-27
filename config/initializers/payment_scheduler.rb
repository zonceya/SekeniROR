# config/initializers/payment_scheduler.rb
return unless Rails.env.production?

require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new

# Check for payment emails every 5 minutes
scheduler.every '5m' do
  PaymentMonitorJob.perform_later(:payments)
end