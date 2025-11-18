class SendRatingNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id, order_id, rating_type)
    user = User.find(user_id)
    order = Order.find(order_id)
    
    if rating_type == 'rate_seller'
      title = "Rate Your Seller"
      message = "How was your experience with #{order.shop.name}?"
    else
      title = "Rate Your Buyer" 
      message = "How was your experience with #{order.buyer.name}?"
    end

    notification = Notification.create!(
      user: user,
      title: title,
      message: message,
      notifiable: order,
      notification_type: 'rating_reminder'
    )

    # Send FCM notification
    if user.firebase_token.present?
      FirebaseNotificationService.deliver_later(notification)
    end
  end
end