module Api
  module V1
    class OrdersController < Api::V1::BaseController
      before_action :authenticate_request!
      before_action :set_order, except: [:create]
      before_action :authorize_order_access, only: [:show, :cancel, :addresses]
      skip_before_action :verify_authenticity_token

      # POST /orders
      def create
        Rails.logger.info "Creating order with params: #{order_params}"
  
        # First create a hold
        hold = Hold.create!(
          item_id: order_params[:item_id],
          user_id: current_user.id,
          quantity: order_params[:quantity] || 1,
          expires_at: 2.minutes.from_now,
          status: :awaiting_payment
        )
        
        hold.item.with_lock do
          if hold.item.can_fulfill?(hold.quantity)
            hold.item.increment!(:reserved, hold.quantity)
          else
            hold.destroy
            render json: { error: "Item cannot fulfill this quantity" }, status: :unprocessable_entity and return
          end
        end
        
        # Then create the order with the hold
        result = Orders::OrderCreator.call(
          order_params.merge(
            buyer_id: current_user.id,
            hold_id: hold.id
          )
        )

        if result.success?
          order = result.order
          render_order(order, :created)
        else
          # If order creation fails, expire the hold immediately
          hold.expire! if hold.persisted?
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error "Order creation error: #{e.message}"
        render json: { errors: [e.message] }, status: :unprocessable_entity
      end

      # GET /orders/:id
      def show
        render json: serialized_order, status: :ok
      rescue => e
        Rails.logger.error "Order show failed: #{e.message}"
        render json: { error: "Failed to process order" }, status: :internal_server_error
      end

      # PATCH /orders/:id/addresses
      def addresses
        if @order.may_update_address?
          if @order.update_addresses(address_params)
            render_order(@order)
          else
            render_error(@order.errors.full_messages, :unprocessable_entity)
          end
        else
          render_error("Address update not allowed in current order state", :forbidden)
        end
      end

      # POST /orders/:id/cancel
      def cancel
        result = cancel_order_service.call(@order, cancellation_params)

        if result.success?
          render_order(result.order)
        else
          render_error(result.errors)
        end
      end    

      private

      def create_order_service
        Orders::OrderCreator
      end

      def cancel_order_service
        Orders::OrderCanceller
      end

      def set_order
        @order = Order.includes(:order_items, :shop).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error('Order not found', :not_found)
      end

      def authorize_order_access
        unless @order.buyer_id == current_user.id || @order.shop.user_id == current_user.id
          render_forbidden
        end
      end

      def cache_key
        "api/v1/orders/#{@order.id}-#{@order.updated_at.to_i}"
      end

      def serialized_order
        Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          OrderSerializer.new(@order).as_json
        end
      end

      def order_params
        params.require(:order).permit(
          :item_id,
          :shop_id,
          :quantity,
          shipping_address: [:street, :city, :province, :country, :postal_code],
          billing_address: [:same_as_shipping, :street, :city, :province, :country, :postal_code]
        )
      end

      def address_params
        params.require(:order).permit(
          shipping_address: [:street, :city, :province, :country, :postal_code],
          billing_address: [:same_as_shipping, :street, :city, :province, :country, :postal_code]
        )
      end

      def cancellation_params
        params.permit(:reason)
      end

      def render_order(order, status = :ok)
        render json: OrderSerializer.new(order).as_json, status: status
      end

      def render_error(errors, status = :unprocessable_entity)
        render json: { errors: Array(errors) }, status: status
      end

      def render_forbidden
        render json: { error: 'Access denied' }, status: :forbidden
      end
    end
  end
end