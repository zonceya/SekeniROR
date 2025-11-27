# app/jobs/expire_holds_job.rb
class ExpireHoldsJob < ApplicationJob
  queue_as :critical # Use a dedicated queue for important jobs
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform
    Rails.logger.info "[ExpireHoldsJob] Starting hold expiration process"
    
    Hold.expired.find_each(batch_size: 100) do |hold|
      expire_hold_with_safety(hold)
    end
    
    Rails.logger.info "[ExpireHoldsJob] Completed hold expiration process"
  end

  private

  def expire_hold_with_safety(hold)
    Rails.logger.info "[ExpireHoldsJob] Processing hold #{hold.id}"
    
    hold.expire!
    
    # Additional logging for success
    Rails.logger.info "[ExpireHoldsJob] Successfully expired hold #{hold.id}"
  rescue => e
    Rails.logger.error "[ExpireHoldsJob] Error expiring hold #{hold.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Report to error monitoring (e.g., Sentry, Rollbar)
    ErrorTracker.report(e, context: { hold_id: hold.id })
    
    # Re-raise to trigger Sidekiq's retry mechanism
    raise
  end
end