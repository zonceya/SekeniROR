module Api
  module V1
    class OrdersController < Api::V1::BaseController
      # Debugging statements (remove in production)
      puts "[CLASS LOAD] Ancestors: #{ancestors}"
      puts "[CLASS LOAD] Included modules: #{included_modules}"

      before_action do
        puts "[REQUEST] Can respond to authenticate_user!?: #{respond_to?(:authenticate_user!)}"
        puts "[REQUEST] Method source: #{method(:authenticate_user!).source_location}" if respond_to?(:authenticate_user!)
      end

      before_action :authenticate_request!
      before_action :set_order, except: [:create]
      before_action :authorize_order_access, only: [:show, :cancel, :addresses]
      skip_before_action :verify_authenticity_token

      # POST /orders
      def create
        Rails.logger.debug "OrderItem class available before creation: #{defined?(OrderItem)}"
        result = Orders::OrderCreator.call(order_params.merge(buyer_id: current_user.id))

        if result.success?
          order = result.respond_to?(:value!) ? result.value! : result.order
          render_order(result.value!, :created)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      # GET /orders/:id
      def show
        render_order(@order)
      end

      # PATCH /orders/:id/addresses
      def addresses
        if @order.may_update_address? && @order.update_addresses(address_params)
          render_order(@order)
        else
          render_error(@order.errors.full_messages.presence || "Address update not allowed")
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
        @order = Order.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error('Order not found', :not_found)
      end

      def authorize_order_access
        unless @order.buyer_id == current_user.id || @order.shop.user_id == current_user.id
          render_forbidden
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