# app/serializers/admin_order_serializer.rb
class AdminOrderSerializer
  include FastJsonapi::ObjectSerializer

  # Match these exactly with your model attributes
  attributes :id, :order_number, :order_status, :payment_status,
             :price, :service_fee, :total_amount,  # Note: using total_amount not total_price
             :created_at, :updated_at, :admin_notes,
             :shipping_address, :billing_address

  attribute :status_label do |order|
    order.status_label
  end

  attribute :buyer do |order|
    {
      id: order.buyer.id,
      name: order.buyer.name,
      email: order.buyer.email
    }
  end

  attribute :shop do |order|
    {
      id: order.shop.id,
      name: order.shop.name
    }
  end

  attribute :items do |order|
    order.order_items.map do |item|
      {
        id: item.id,
        name: item.item.name,  # Assuming Item has a name attribute
        quantity: item.quantity,
        unit_price: item.actual_price,
        total_price: item.total_price
      }
    end
  end
end