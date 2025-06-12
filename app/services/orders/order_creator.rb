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
      @reserved_quantity = (@params[:quantity] || 1).to_i
    end

    def call
      item = nil
      order = nil

      ActiveRecord::Base.transaction do
        item = find_item
        validate_item_shop(item)
        validate_quantity(item)
        order = create_order(item)
        reserve_inventory(item)
        create_order_item(order, item)
        calculate_totals(order)
      end

      Success.new(order)
    rescue => e
      Rails.logger.error "Order creation failed: #{e.message}\n#{e.backtrace.join("\n")}"
      Failure.new(@errors.presence || [e.message])
    end

    private

    def find_item
      Item.lock.find(@params[:item_id])
    rescue ActiveRecord::RecordNotFound
      @errors << "Item not found"
      raise
    end

    def validate_item_shop(item)
      raise "Item does not belong to the requested shop" unless item.shop_id == @params[:shop_id].to_i
    end

    def validate_quantity(item)
      available = item.quantity - item.reserved
      raise "Not enough inventory. Available: #{available}, Requested: #{@reserved_quantity}" unless available >= @reserved_quantity
    end

    def reserve_inventory(item)
      item.with_lock do
        item.reserved += @reserved_quantity
        item.save!
      end
    end

    def create_order(item)
      Rails.logger.info "Creating order for buyer_id=#{@params[:buyer_id]} and shop_id=#{@params[:shop_id]}"

      order = Order.create!(
        buyer_id: @params[:buyer_id],
        shop_id: @params[:shop_id],
        order_status: :pending,
        payment_status: :unpaid,
        shipping_address: @params[:shipping_address],
        billing_address: @params[:billing_address] || @params[:shipping_address],
        price: 0,
        service_fee: 0,
        total_amount: 0
      )

      Rails.logger.info "Order created with ID: #{order.id}"
      order
    end

    def create_order_item(order, item)
      order.order_items.create!(
        item_id: item.id,
        item_name: item.name,
        quantity: @reserved_quantity,
        actual_price: item.price,
        total_price: item.price * @reserved_quantity,
        shop_id: item.shop_id
      )
    end

    def calculate_totals(order)
      subtotal = order.order_items.sum { |item| item.actual_price * item.quantity }
      service_fee = calculate_service_fee(subtotal)

      order.update!(
        price: subtotal,
        service_fee: service_fee,
        total_amount: subtotal + service_fee
      )
    end

    def calculate_service_fee(subtotal)
      (subtotal * 0.05).round(2)
    end
  end

  class Success
    attr_reader :order

    def initialize(order)
      @order = order
    end

    def success?
      true
    end

    def value
      order
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