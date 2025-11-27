# app/controllers/api/v1/payments_controller.rb
module Api
  module V1
    class PaymentsController < Api::V1::BaseController
      before_action :authenticate_request!
      before_action :set_order, only: [:initiate, :status, :transactions, :upload_proof,:confirm_payment]
      before_action :authorize_order_access, only: [:initiate, :status, :transactions, :upload_proof,:confirm_payment]

      # POST /api/v1/orders/:id/initiate_payment
      def initiate
        if @order.may_initiate_payment?
          @order.update!(
            payment_status: :processing,
            payment_initiated_at: Time.current,
            payment_expires_at: 2.minutes.from_now
          )
           
          # Create a background job to handle expiration
          OrderPaymentExpiryJob.set(wait_until: @order.payment_expires_at).perform_later(@order.id)
          
          render json: {
            order_id: @order.id,
            amount_due: @order.total_amount,
            currency: "ZAR",
            bank_details: {
              account_name: "Sekeni Pty Ltd",
              account_number: "1234567890",
              bank_name: "Capitec Bank",
              branch_code: "470010"
            },
            reference: @order.order_number,
            instructions: "Use the order number as reference when making payment.",
            expires_at: @order.payment_expires_at,
            countdown_seconds: 48.hours.to_i
          }, status: :ok
        else
          render json: { error: "Payment cannot be initiated for this order" }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/orders/:id/payment_status
    # app/controllers/api/v1/payments_controller.rb
    def status
      render json: {
        order: {
          id: @order.id,
          order_number: @order.order_number,
          status: @order.order_status,
          payment_status: @order.payment_status,
          total_amount: @order.total_amount,
          currency: "ZAR"
        },
        payment: {
          initiated_at: @order.payment_initiated_at,
          expires_at: @order.payment_expires_at,
          paid_at: @order.paid_at,
          time_remaining_seconds: @order.payment_time_remaining,
          is_expired: @order.payment_expired?,
          bank_details: {
            account_name: "Sekeni Pty Ltd",
            account_number: "1234567890",
            bank_name: "Capitec Bank",
            branch_code: "470010",
            reference: @order.order_number
          }
        },
        transactions: @order.order_transactions.order(created_at: :desc).map do |txn|
          {
            id: txn.id,
            amount: txn.amount,
            status: txn.txn_status,
            type: txn.payment_method,
            bank_reference: txn.bank_ref_num,
            timestamp: txn.txn_time,
            description: transaction_description(txn)
          }
        end
      }, status: :ok
    end

      # GET /api/v1/orders/:id/payment_transactions
    def transactions
      # Get both order transactions and payment events
      order_transactions = @order.order_transactions.order(created_at: :desc)
      payment_events = @order.payment_events.order(created_at: :desc)
      
      transactions = (order_transactions + payment_events).sort_by(&:created_at).reverse
      
        formatted_transactions = transactions.map do |transaction|
        if transaction.is_a?(OrderTransaction)
          format_order_transaction(transaction)
        else
          format_payment_event(transaction)
        end
      end
  
  render json: formatted_transactions, status: :ok
     end

      # POST /api/v1/orders/:id/upload_payment_proof
      def upload_proof
        if params[:payment_proof].present?
          # Handle file upload logic here
          # You might want to use Active Storage or CarrierWave
          @order.update!(payment_status: :awaiting_verification)
          
          # Notify admin about proof upload
          AdminMailer.payment_proof_uploaded(@order).deliver_later
          
          render json: { 
            message: "Payment proof uploaded successfully. Awaiting verification.",
            order_id: @order.id,
            status: @order.payment_status
          }, status: :ok
        else
          render json: { error: "Payment proof file is required" }, status: :unprocessable_entity
        end
      end

    
def confirm_payment
  if @order.may_mark_as_paid?
    @order.mark_as_paid

    # Find or create chat room (handles uniqueness constraint)
    chat_room = ChatRoom.find_or_create_by(order: @order) do |room|
      room.buyer = @order.buyer
      room.seller = @order.shop.user
      room.room_id = "order_#{@order.id}_#{SecureRandom.hex(4)}"
    end

    # Send system message
    ChatMessage.create!(
      chat_room: chat_room,
      sender: @order.buyer,
      content: "Payment received. You can now chat to arrange collection or delivery.",
      message_type: :system
    )

    # Send FCM notifications
    send_chat_notifications(chat_room)

    render json: {
      message: "Payment confirmed successfully",
      order: {
        id: @order.id,
        order_number: @order.order_number,
        status: @order.order_status,
        payment_status: @order.payment_status,
        paid_at: @order.paid_at
      },
      chat_room: {
        id: chat_room.id,
        room_id: chat_room.room_id
      },
      notification: "Chat room created. Both parties notified."
    }, status: :ok
  else
    render json: { error: "Payment cannot be confirmed for this order" }, status: :unprocessable_entity
  end
end

private

def send_chat_notifications(chat_room)
  # Notify both buyer and seller
  [chat_room.buyer, chat_room.seller].each do |user|
    notification = Notification.create!(
      user: user,
      title: "Chat started for Order ##{@order.order_number}",
      message: "Payment received. You can now chat to arrange collection or delivery.",
      notifiable: chat_room,
      notification_type: 'message_received' # ✅ Use valid notification type
    )
    
    # Send FCM notification
    FirebaseNotificationService.deliver_later(notification) if user.firebase_token.present?
  end
rescue StandardError => e
  Rails.logger.error "Error sending chat notifications: #{e.message}"
  # Don't fail the entire request if notifications fail
end

      private
    def send_chat_notifications(chat_room)
      # Notify both buyer and seller
      [chat_room.buyer, chat_room.seller].each do |user|
        notification = Notification.create!(
          user: user,
          title: "Chat started for Order ##{@order.order_number}",
          message: "Payment received. You can now chat to arrange collection or delivery.",
          notifiable: chat_room,
          notification_type: 'chat_started'
        )
        
        # Send FCM notification
        FirebaseNotificationService.deliver_later(notification)
      end
    end
    def set_order
  # For nested routes, use order_id instead of id
        order_id = params[:order_id] || params[:id]
        @order = Order.includes(:order_items, :shop).find(order_id)
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Order not found' }, status: :not_found
    end

    def format_order_transaction(transaction)
      {
        id: transaction.id,
        type: "bank_transaction",
        amount: transaction.amount,
        status: transaction.txn_status,
        payment_method: transaction.payment_method,
        bank_reference: transaction.bank_ref_num,
        bank: transaction.bank,
        created_at: transaction.txn_time || transaction.created_at,
        metadata: {
          transaction_id: transaction.id,
          processed_by: "system"
        }
      }
    end
   def format_payment_event(event)
      {
        id: event.id,
        type: "payment_event",
        event_type: event.event_type,
        status: event.status,
        amount: event.amount,
        created_at: event.created_at,
        metadata: event.metadata || {}
      }
    end
      def authorize_order_access
        unless @order.buyer_id == current_user.id || @order.shop.user_id == current_user.id
          render json: { error: 'Access denied' }, status: :forbidden
        end
      end
    end
  end
end