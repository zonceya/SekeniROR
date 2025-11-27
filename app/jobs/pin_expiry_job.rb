# app/jobs/pin_expiry_job.rb
class PinExpiryJob < ApplicationJob
  queue_as :default

  def perform(pin_verification_id)
    pin_verification = PinVerification.find_by(id: pin_verification_id)
    return unless pin_verification&.pending?

    if pin_verification.expired?
      pin_verification.update!(status: :expired)
      
      # Notify both parties about expiry
      notify_pin_expiry(pin_verification)
    end
  end

  private

  def notify_pin_expiry(pin_verification)
    message = "PIN for Order ##{pin_verification.order.order_number} has expired"

    [pin_verification.buyer, pin_verification.seller].each do |user|
      notification = Notification.create!(
        user: user,
        title: "PIN Expired",
        message: message,
        notifiable: pin_verification,
        notification_type: 'system_alert'
      )

      if user.firebase_token.present?
        FirebaseNotificationService.deliver_later(notification)
      end
    end

    # Also send via chat
    chat_room = ChatRoom.find_by(order: pin_verification.order)
    if chat_room
      ChatMessage.create!(
        chat_room: chat_room,
        sender: pin_verification.buyer,
        content: message,
        message_type: :system
      )
    end
  end
end