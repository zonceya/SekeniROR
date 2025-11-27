# app/jobs/firebase_delivery_job.rb
class FirebaseDeliveryJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(notification_id)
    notification = Notification.find_by(id: notification_id)
    return unless notification
    
    # For now, just mark as delivered for testing
    notification.update!(
      status: 'delivered',
      firebase_sent: true,
      delivered_at: Time.current
    )
    
    Rails.logger.info "✅ Notification #{notification_id} marked as delivered"
  end
end