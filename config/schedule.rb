return unless Rails.env.development? || Rails.env.test?

require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new

# Run every minute
scheduler.every '1m' do
  Rails.logger.info "[rufus-scheduler] Running ExpireHoldsJob"
  ExpireHoldsJob.perform_later
end
