# app/jobs/order_payment_expiry_job.rb
class OrderPaymentExpiryJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find(order_id)
    return unless order.payment_processing? && order.payment_expires_at.past?

    ActiveRecord::Base.transaction do
      order.update!(
        payment_status: :expired,
        order_status: :cancelled
      )
      
      # Release the inventory hold
      Inventory::HoldReleaseService.new(order.hold).call if order.hold
      
      # Notify user
      OrderMailer.payment_expired(order).deliver_later
    end
  end
end