return unless Rails.env.development? || Rails.env.test?

require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new

# Run every minute
# config/schedule.rb
# Monitor payments every 5 minutes (strict filtering)
every '*/5 * * * *' do
  runner "PaymentMonitorJob.perform_later(:payments)"
end

# Broader notification check every hour
every 1.hour do
  runner "PaymentMonitorJob.perform_later(:notifications)"
end

# Cleanup expired payments daily
every 1.day, at: '2:00 am' do
  runner "Order.cleanup_expired_payments"
end

# Weekly full scan on Sundays
every :sunday, at: '3:00 am' do
  runner "PaymentMonitorJob.perform_later(:both)"
end
