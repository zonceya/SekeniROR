# app/services/order_status_change_notifier.rb
class OrderStatusChangeNotifier
  def self.call(order, new_status)
    new(order, new_status).call
  end

  def initialize(order, new_status)
    @order = order
    @new_status = new_status
  end

  def call
    notify_buyer
    notify_seller
    log_status_change
  end

  private

  def notify_buyer
    OrderMailer.status_changed(@order.buyer_email, @order, @new_status).deliver_later
  end

  def notify_seller
    OrderMailer.status_changed(@order.shop.email, @order, @new_status).deliver_later
  end

  def log_status_change
    @order.status_changes.create!(
      status: @new_status,
      changed_by: Current.user&.id,
      notes: "Status changed to #{@new_status}"
    )
  end
end