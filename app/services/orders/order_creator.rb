module Orders
  class OrderCreator
    class << self
      def call(params)
        new(params).call
      end
    end

    def initialize(params)
      @params = params
      @errors = []
    end

    def call
      result = nil
      ActiveRecord::Base.transaction do
        item = find_item
        order = create_order(item)
        create_order_item(order, item)
        calculate_totals(order)
        result = Success.new(order)
      end

      result || Failure.new(@errors)
    rescue => e
      Rails.logger.error "Order creation failed: #{e.message}\n#{e.backtrace.join("\n")}"
      Failure.new([e.message])
    end

    private

    def find_item
      Item.find(@params[:item_id])
    rescue ActiveRecord::RecordNotFound
      @errors << "Item not found"
      raise
    end

    def create_order(item)
      Rails.logger.info "Creating order for buyer_id=#{@params[:buyer_id]} and shop_id=#{item.shop_id}"
      
      order = Order.new(
        buyer_id: @params[:buyer_id],
        shop_id: item.shop_id,
        order_status: :pending,
        payment_status: :unpaid,
        shipping_address: @params[:shipping_address],
        billing_address: @params[:billing_address] || @params[:shipping_address],
        price: 0,
        service_fee: 0,
        total_amount: 0
      )

      if order.save
        Rails.logger.info "Order created with ID: #{order.id}"
        order
      else
        raise "Failed to create order: #{order.errors.full_messages.join(', ')}"
      end
    end

    def create_order_item(order, item)
      order_item = order.order_items.build(
        item_id: item.id,
        item_name: item.name,
        actual_price: item.price,
        total_price: item.price * (@params[:quantity] || 1),
        quantity: @params[:quantity] || 1,
        shop_id: item.shop_id
      )

      unless order_item.save
        Rails.logger.error "Failed to create order item: #{order_item.errors.full_messages}"
        raise ActiveRecord::RecordInvalid, order_item
      end
      
      order_item
    rescue => e
      @errors << "Failed to create order item: #{e.message}"
      raise
    end

    def calculate_totals(order)
      subtotal = order.order_items.sum { |item| item.actual_price * item.quantity }
      service_fee = calculate_service_fee(subtotal)

      order.update!(
        price: subtotal,
        service_fee: service_fee,
        total_amount: subtotal + service_fee
      )
    rescue => e
      @errors << "Failed to calculate totals: #{e.message}"
      raise
    end

    def calculate_service_fee(subtotal)
      (subtotal * 0.05).round(2) # 5% service fee
    end
  end

  # Simple result objects
  class Success
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def success?
      true
    end
  end

  class Failure
    attr_reader :errors

    def initialize(errors)
      @errors = Array(errors)
    end

    def success?
      false
    end
  end
end