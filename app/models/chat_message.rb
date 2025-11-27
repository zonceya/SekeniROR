class ChatMessage < ApplicationRecord
  belongs_to :chat_room
  belongs_to :sender, class_name: 'User'

  validates :content, presence: true

  # Fixed enum syntax for Rails 7+
  enum :message_type, {
    text: 'text',
    system: 'system', 
    file: 'file'
  }, default: :text

  after_create_commit :notify_recipients
  after_create_commit :broadcast_message

  private

 def notify_recipients
  return unless chat_room && sender
    
  recipient = chat_room.other_participant(sender)
  return unless recipient

  # Create notification - use the valid 'message_received' type
  notification = Notification.create!(
    user: recipient,
    title: "New message from #{sender.name}",
    message: content.to_s.truncate(50),
    notifiable: self,
    notification_type: 'message_received' # ✅ Fixed: using valid type
  )

  # Send FCM notification
  if recipient.firebase_token.present?
    FirebaseNotificationService.deliver_later(notification)
  end
rescue StandardError => e
  Rails.logger.error "Error in notify_recipients: #{e.message}"
end

  def broadcast_message
    # For now, just log the broadcast
    # We'll implement Action Cable later
    Rails.logger.info "Broadcasting message #{id} for chat room #{chat_room_id}"
    
    # Uncomment when you set up Action Cable:
    # ChatChannel.broadcast_to(
    #   chat_room,
    #   {
    #     id: id,
    #     content: content,
    #     sender_id: sender_id,
    #     sender_name: sender.name,
    #     created_at: created_at.iso8601,
    #     message_type: message_type
    #   }
    # )
  end
end