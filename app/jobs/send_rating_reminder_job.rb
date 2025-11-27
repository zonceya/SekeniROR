class SendRatingReminderJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find(order_id)
    
    # Send reminder to buyer to rate seller
    SendRatingNotificationJob.perform_later(
      order.buyer_id, 
      order.id, 
      'rate_seller'
    )
    
    # Send reminder to seller to rate buyer
    SendRatingNotificationJob.perform_later(
      order.shop.user_id, 
      order.id, 
      'rate_buyer'
    )
  end
end