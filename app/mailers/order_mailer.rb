# app/mailers/order_mailer.rb
class OrderMailer < ApplicationMailer
  def payment_expired(order)
    @order = order
    mail(to: order.buyer.email, subject: "Payment for order #{order.order_number} has expired")
  end
end