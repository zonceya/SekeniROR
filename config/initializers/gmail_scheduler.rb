require 'rufus-scheduler'

return unless Rails.env.production?

scheduler = Rufus::Scheduler.new

# Check for payment emails every 5 minutes
scheduler.every '5m' do
  PaymentMonitorJob.perform_later(:payments)
end

Rails.logger.info "✅ Payment monitor scheduler started"