# app/services/payment_notification_service.rb
class PaymentNotificationService
  def self.notify_payment_issues
    # Find orders with payment issues
    problematic_orders = Order.where(payment_status: [:awaiting_verification, :amount_mismatch])
    
    problematic_orders.each do |order|
      if order.payment_status == 'amount_mismatch'
        notify_amount_mismatch(order)
      else
        notify_proof_required(order)
      end
    end
  end

  private

  def self.notify_amount_mismatch(order)
    message = <<~TEXT
      Hi #{order.buyer.name},
      
      We received your payment of R#{order.total_amount}, but it doesn't match the order amount.
      
      Order ##{order.order_number}: R#{order.total_amount}
      Amount received: R#{order.payment_records.last.amount}
      
      Please contact support or upload proof of payment.
      
      Thank you,
      #{order.shop.name}
    TEXT

    send_notification(order.buyer, "Payment Amount Mismatch", message)
  end

  def self.notify_proof_required(order)
    message = <<~TEXT
      Hi #{order.buyer.name},
      
      We couldn't automatically verify your payment for order ##{order.order_number}.
      
      Please upload your payment proof here: #{order_payment_url(order)}
      
      Or email your proof to: payments@yourdomain.com
      
      Thank you,
      #{order.shop.name}
    TEXT

    send_notification(order.buyer, "Payment Verification Required", message)
  end

  def self.send_notification(user, subject, message)
    # In-app notification
    Notification.create!(
      user: user,
      title: subject,
      message: message,
      type: :payment_issue
    )
    
    # Email notification
    UserMailer.payment_issue(user, subject, message).deliver_later
  end
end