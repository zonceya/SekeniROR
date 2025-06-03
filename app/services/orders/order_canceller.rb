module Orders
    class OrderCanceller
      include ServicePattern
  
      def initialize(order, params = {})
        @order = order
        @reason = params[:reason]
      end
  
      def call
        return Failure.new(["Order cannot be cancelled"]) unless @order.may_cancel?
  
        ActiveRecord::Base.transaction do
          @order.update!(
            order_status: :cancelled,
            cancelled_at: Time.current,
            cancellation_reason: @reason,
            payment_status: determine_payment_status
          )
          
          # Future: Add inventory release here
          Success.new(@order)
        end
      rescue => e
        Failure.new([e.message])
      end
  
      private
  
      def determine_payment_status
        @order.paid? ? :refunded : @order.payment_status
      end
    end
  end