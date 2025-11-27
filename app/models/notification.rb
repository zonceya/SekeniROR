class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  enum :status, { pending: 'pending', delivered: 'delivered', failed: 'failed' }
  
  enum :notification_type, { 
    payment_confirmation: 'payment_confirmation',
    payment_received: 'payment_received', 
    order_placed: 'order_placed',
    message_received: 'message_received',
    system_alert: 'system_alert',
    chat_started: 'chat_started',
    pin_verification: 'pin_verification',
    refund_processed: 'refund_processed',
    order_cancelled: 'order_cancelled',
    dispute_filed: 'dispute_filed',
    dispute_alert: 'dispute_alert',
    admin_alert: 'admin_alert',
    account_suspended: 'account_suspended'
  }

  validates :title, :message, :notification_type, presence: true
  scope :unread, -> { where(read: false) }
  scope :pending_delivery, -> { where(status: 'pending') }

  def mark_as_read
    update(read: true)
  end

  def deliver_via_firebase
    FirebaseNotificationService.deliver(self)
  end
end