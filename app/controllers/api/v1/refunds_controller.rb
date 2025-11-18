# app/controllers/api/v1/refunds_controller.rb
module Api
  module V1
    class RefundsController < BaseController
      before_action :authenticate_user!
      before_action :set_order, only: [:cancel_order, :dispute, :show]
      before_action :authorize_order_access, only: [:cancel_order, :dispute, :show]

      # POST /api/v1/orders/:id/cancel_order
      def cancel_order
        # This is the CLEAN option - buyer cancels BEFORE PIN entry
        unless @order.paid?
          return render json: { 
            success: false, 
            error: "Order must be paid to cancel" 
          }, status: :unprocessable_entity
        end

        # Check if PIN has been generated
        if @order.pin_verifications.active.exists?
          return render json: {
            success: false,
            error: "PIN already generated. Cannot cancel order. Please use dispute system."
          }, status: :unprocessable_entity
        end

        result = RefundService.process_buyer_cancellation(@order, cancellation_params)

        if result[:success]
          render json: {
            success: true,
            message: "Order cancelled successfully. Refund processing.",
            refund: result[:refund],
            order_status: @order.order_status
          }, status: :ok
        else
          render json: {
            success: false,
            errors: result[:errors]
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/orders/:id/dispute
      def dispute
        # This is for cases where seller tries to force transaction
        unless @order.paid?
          return render json: { 
            success: false, 
            error: "Order must be paid to dispute" 
          }, status: :unprocessable_entity
        end

        # Check if PIN verification is active (buyer is at collection point)
        active_pin = @order.pin_verifications.active.last
        unless active_pin
          return render json: {
            success: false,
            error: "No active PIN verification. Use cancel_order instead."
          }, status: :unprocessable_entity
        end

        result = RefundService.process_dispute(@order, dispute_params, current_user)

        if result[:success]
          render json: {
            success: true,
            message: "Dispute filed successfully. Admin will review within 48 hours.",
            dispute: result[:dispute],
            refund: result[:refund],
            order_status: @order.order_status
          }, status: :ok
        else
          render json: {
            success: false,
            errors: result[:errors]
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/orders/:id/refund_status
      def show
        begin
          refund = Refund.find_by(order_id: @order.id)
          
          Rails.logger.info "DEBUG: Looking for refund for order #{@order.id}, found: #{refund.present?}"
          
          unless refund
            Rails.logger.warn "DEBUG: No refund found for order #{@order.id}"
            return render json: {
              success: false,
              error: "No refund found for this order"
            }, status: :not_found
          end

          Rails.logger.info "DEBUG: Refund found: #{refund.id}, status: #{refund.status}"
          
          render json: {
            success: true,
            refund: serialize_refund(refund)
          }, status: :ok
        rescue => e
          Rails.logger.error "DEBUG: Error in refunds#show: #{e.message}"
          render json: {
            success: false,
            error: "Internal server error"
          }, status: :internal_server_error
        end
      end

      private

      def set_order
        puts "DEBUG: Looking for order with ID: #{params[:id]}"
        
        # Try to find by UUID first - use params[:id] instead of params[:order_id]
        @order = Order.find_by(id: params[:id])
        
        # If not found by UUID, try by order_number
        unless @order
          @order = Order.find_by(order_number: params[:id])
        end
        
        # If still not found, try by ID as string (for UUID)
        unless @order
          @order = Order.find_by(id: params[:id].to_s)
        end
        
        unless @order
          puts "DEBUG: Order not found with any method"
          render json: { 
            success: false, 
            error: 'Order not found' 
          }, status: :not_found
        else
          puts "DEBUG: Order found: #{@order.id} - #{@order.order_number}"
        end
      end

      def authorize_order_access
        unless @order.buyer_id == current_user.id || @order.shop.user_id == current_user.id
          render json: { 
            success: false, 
            error: 'Access denied' 
          }, status: :forbidden
        end
      end

      def cancellation_params
        params.require(:cancellation).permit(
          :reason,
          :notes
        )
      end

      def dispute_params
        params.require(:dispute).permit(
          :reason,
          :description,
          :evidence_photos => []
        )
      end

      def serialize_refund(refund)
        return nil unless refund
        
        # Basic attributes only - no associations
        {
          id: refund.id,
          order_id: refund.order_id,
          amount: refund.amount.to_f,
          status: refund.status,
          reason: refund.reason,
          refund_type: refund.refund_type,
          processed_at: refund.processed_at&.iso8601,
          estimated_completion: refund.estimated_completion&.iso8601,
          created_at: refund.created_at&.iso8601,
          updated_at: refund.updated_at&.iso8601
        }
      end
    end
  end
end