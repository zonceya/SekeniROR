module Orders
  class OrderCanceller    
    def self.call(order, params = {})
      new(order, params).call
    end

    def initialize(order, params = {})
      @order = order
      @reason = params[:reason]
    end

    def call
      if @order.order_cancelled?
        return failure("Order #{@order.id} is already cancelled")
      end

      unless @order.may_cancel?
        return failure("Order #{@order.id} cannot be cancelled - Status: #{@order.order_status}, Payment: #{@order.payment_status}")
      end

      ActiveRecord::Base.transaction do
        @order.update!(
          order_status: :cancelled,
          cancelled_at: Time.current,
          cancellation_reason: @reason,
          payment_status: @order.payment_paid? ? :refunded : @order.payment_status
        )
        success(@order)
      end
    rescue => e
      failure(e.message)
    end

    private

    def success(value)
      OpenStruct.new(success?: true, order: value)
    end

    def failure(error)
      OpenStruct.new(success?: false, errors: Array(error))
    end
  end
end