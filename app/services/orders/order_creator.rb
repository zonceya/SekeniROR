module Orders
  class OrderCreator
    HOLD_DURATION = 5.minutes # Change to 24.hours in production

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
      hold = nil

      ActiveRecord::Base.transaction do
        item = find_item
        validate_item_shop(item)

        order = create_initial_order

        if @params[:hold_id]
          hold = process_existing_hold(item, order)
        else
          validate_quantity(item)
          hold = create_new_hold(item, order)
          reserve_inventory(item)
        end

        complete_order_setup(order, item)

        Success.new(order)
      end
    rescue => e
      handle_creation_failure(hold, e)
    end

    private

    def find_item
      Item.lock.find(@params[:item_id])
    rescue ActiveRecord::RecordNotFound
      @errors << "Item not found"
      raise
    end

    def validate_item_shop(item)
      unless item.shop_id == @params[:shop_id].to_i
        raise "Item does not belong to the requested shop"
      end
    end

    def create_initial_order
      Order.create!(
        buyer_id: @params[:buyer_id],
        shop_id: @params[:shop_id],
        order_status: :pending,
        payment_status: :unpaid,
        shipping_address: @params[:shipping_address],
        billing_address: @params[:billing_address] || @params[:shipping_address],
        price: 0,
        service_fee: 0,
        total_amount: 0,
         order_number: generate_order_number
      )
    end
        def generate_order_number
      date_code = Time.current.strftime("%y%m%d")
      buyer_initial = User.find(@params[:buyer_id]).name.first.upcase
      sequence_num = Order.where("order_number LIKE ?", "#{date_code}%").count + 1
      "#{date_code}#{buyer_initial}#{sequence_num.to_s.rjust(4, '0')}"
    end
    def process_existing_hold(item, order)
      hold = Hold.lock.find(@params[:hold_id])
      validate_hold(hold, item)
      @reserved_quantity = hold.quantity
      hold.update!(
        order: order,
        expires_at: Time.current + HOLD_DURATION
      )
      hold
    end

    def validate_hold(hold, item)
      unless hold.user_id == @params[:buyer_id] &&
             hold.item_id == item.id &&
             hold.status_awaiting_payment? &&
             hold.expires_at > Time.current
        raise "Invalid or expired hold"
      end
    end

    def create_new_hold(item, order)
      buffer = rand(10..30).seconds
       expires_at = Time.current + HOLD_DURATION + buffer
      Hold.create!(
        item: item,
        user_id: @params[:buyer_id],
        order: order,
        quantity: @reserved_quantity,
        expires_at: expires_at,
        status: :awaiting_payment
      )
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

    def complete_order_setup(order, item)
      create_order_item(order, item)
      calculate_totals(order)
         #  order.update!(order_status: :processing)
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
      subtotal = order.order_items.sum { |oi| oi.total_price }
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

   def handle_creation_failure(hold, error)
      if hold&.status_awaiting_payment? && !@params[:hold_id]
        begin
          # Use either HoldReleaseService OR hold.expire!, not both
          Inventory::HoldReleaseService.new(hold).call
        rescue => rollback_error
          Rails.logger.error "Hold release failed: #{rollback_error.message}"
        end
      end

  Rails.logger.error "Order creation failed: #{error.message}\n#{error.backtrace.join("\n")}"
  Failure.new(@errors.presence || [error.message])
end

    class Success
      attr_reader :order

      def initialize(order)
        @order = order
      end

      def success? = true
      def value = order
    end

    class Failure
      attr_reader :errors

      def initialize(errors)
        @errors = Array(errors)
      end

      def success? = false
    end
  end
end
