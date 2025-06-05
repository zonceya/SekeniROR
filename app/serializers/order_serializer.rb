class OrderSerializer
    def initialize(order)
      @order = order
    end
  
    def as_json
      {
        id: @order.id,
        status: @order.status,
       payment_status: @order.payment_status || 'unpaid',
        buyer_id: @order.buyer_id,
        shop_id: @order.shop_id,
        price_breakdown: {
          subtotal: @order.price,
          service_fee: @order.service_fee,
          total: @order.total_amount
        },
        items: @order.order_items.map { |item| serialize_item(item) },
        addresses: {
          shipping: @order.shipping_address,
          billing: @order.billing_address
        },
        timestamps: {
          created_at: @order.created_at,
          cancelled_at: @order.try(:cancelled_at) # 
        },
        cancellable: @order.may_cancel?,
        cancellation_reason: @order.cancellation_reason
      }.compact
    end
  
    private
  
    def serialize_item(item)
      {
        id: item.id,
        item_id: item.item_id,
        name: item.item_name,
        quantity: item.quantity,
        unit_price: item.actual_price,
        total_price: item.total_price
      }
    end
  end