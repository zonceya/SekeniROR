class OrderSerializer
  include JSONAPI::Serializer

  attributes :id, :order_number, :status, :payment_status, :buyer_id, :shop_id,
             :price_breakdown, :items, :addresses, :timestamps, :cancellable

  def initialize(order)
    @order = order || NullOrder.new
  end

  def as_json(*)
    {
      id: @order.id.to_s,
      order_number: @order.order_number,
      status: @order.order_status,
      payment_status: @order.payment_status || 'unpaid',
      buyer_id: @order.buyer_id,
      shop_id: @order.shop_id,
      price_breakdown: {
        subtotal: @order.price.to_f,
        service_fee: @order.service_fee.to_f,
        total: @order.total_amount.to_f
      },
      items: serialized_items,
      addresses: {
        shipping: @order.shipping_address || {},
        billing: @order.billing_address || {}
      },
      timestamps: {
        created_at: @order.created_at,
        updated_at: @order.updated_at,
        cancelled_at: @order.try(:cancelled_at)
      }.compact,
      cancellable: @order.respond_to?(:may_cancel?) && @order.may_cancel?
    }.compact
  rescue => e
    Rails.logger.error "Order serialization failed: #{e.message}"
    { error: "Failed to serialize order data" }
  end

  private

  def serialized_items
    Array(@order.order_items).map do |item|
      {
        id: item.id.to_s,
        item_id: item.item_id.to_s,
        name: item.try(:item_name) || 'Unnamed Item',
        quantity: item.quantity.to_i,
        unit_price: item.try(:actual_price).to_f,
        total_price: item.try(:total_price).to_f
      }
    end
  end

  # Null object to handle nil safely
  class NullOrder
    def method_missing(*)
      nil
    end

    def respond_to_missing?(*)
      true
    end
  end
end
