# app/controllers/api/v1/pin_verifications_controller.rb
module Api
  module V1
    class PinVerificationsController < Api::V1::BaseController
      before_action :authenticate_request!
      before_action :set_order, except: [:verify_pin]
      before_action :authorize_order_access, except: [:verify_pin]
      before_action :set_pin_verification, only: [:show, :verify_pin, :resend, :cancel]

      # POST /api/v1/orders/:order_id/generate_pin
    
    def generate_pin
      # Check if order is paid
      unless @order.paid?
        return render json: { 
          error: "Order must be paid before generating PIN" 
        }, status: :unprocessable_entity
      end

      # Check if there's already an active PIN
      active_pin = @order.pin_verifications.active.last
      
      if active_pin
        render json: {
          pin_verification: serialize_pin_verification(active_pin),
          message: "PIN already generated and active"
        }, status: :ok
        return
      end

      pin_verification = PinVerification.generate_for_order(@order)

      # Send PIN to seller via FCM
      send_pin_to_seller(pin_verification)

      render json: {
        pin_verification: serialize_pin_verification(pin_verification),
        message: "PIN generated and sent to seller"
      }, status: :created
     rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
    def set_order
      puts "DEBUG: Params received: #{params.inspect}"
      order_id = params[:order_id] || params[:id]
      puts "DEBUG: Looking for order with ID: #{order_id}"
      
      @order = Order.find(order_id)
      puts "DEBUG: Order found: #{@order.id}"
    rescue ActiveRecord::RecordNotFound => e
      puts "DEBUG: Order not found error: #{e.message}"
      render json: { error: 'Order not found' }, status: :not_found
    end
      # GET /api/v1/orders/:order_id/pin_verification
      def show
        render json: {
          pin_verification: serialize_pin_verification(@pin_verification)
        }, status: :ok
      end
    def set_pin_verification
      puts "DEBUG: Setting pin verification with params: #{params.inspect}"
      
      @pin_verification = if params[:id] && params[:id] != @order&.id.to_s
        # For verify_pin action - using pin_verification ID
        PinVerification.find(params[:id])
      else
        # For show, resend, cancel actions - using order's last pin_verification
        @order.pin_verifications.last
      end
      
      puts "DEBUG: Pin verification found: #{@pin_verification&.id}"
    rescue ActiveRecord::RecordNotFound => e
      puts "DEBUG: Pin verification not found error: #{e.message}"
      render json: { error: 'PIN verification not found' }, status: :not_found
    end
      # POST /api/v1/pin_verifications/:id/verify_pin
      # app/controllers/api/v1/pin_verifications_controller.rb
    def verify_pin
      unless params[:pin_code].present?
        return render json: { error: "PIN code is required" }, status: :unprocessable_entity
      end

      # Set the order from the pin_verification
      @order = @pin_verification.order
      
      if @pin_verification.verify!(params[:pin_code])
        # Update order status first
        update_order_after_verification(@order)
        
        # Credit seller's wallet with item amount (minus fees)
        WalletService.credit_seller_for_order_completion(@order)
        
        # Release buyer's held funds (if any)
        WalletService.release_buyer_hold(@order)
        
        # Notify both parties about successful verification
        send_verification_notifications(@pin_verification, true)
        SendRatingReminderJob.set(wait: 2.hours).perform_later(@order.id)
        render json: {
          success: true,
          message: "Collection verified successfully",
          transaction: {
            id: @pin_verification.id,
            status: @pin_verification.status,
            verified_at: @pin_verification.verified_at
          },
          order: {
            id: @order.id,
            order_number: @order.order_number,
            status: @order.order_status,
            completed_at: @order.completed_at
          },
          wallet_update: {
            seller_credited: true,
            buyer_hold_released: true
          },
          ui_data: build_ui_data(@pin_verification)
        }, status: :ok
      else
        send_verification_notifications(@pin_verification, false)
        render json: {
          success: false,
          error: "Invalid or expired PIN code"
        }, status: :unprocessable_entity
      end
    end

      # POST /api/v1/orders/:order_id/resend_pin
      def resend
        if @pin_verification.active?
          # Resend the same PIN
          send_pin_to_seller(@pin_verification)
          
          render json: {
            message: "PIN resent to seller",
            pin_verification: serialize_pin_verification(@pin_verification)
          }, status: :ok
        else
          render json: { error: "Cannot resend expired or used PIN" }, status: :unprocessable_entity
        end
      end
# GET /api/v1/orders/:order_id/seller_pin
    def seller_pin
      pin_verification = @order.pin_verifications.active.last
      
      unless pin_verification
        return render json: { 
          error: "No active PIN found for this order",
          order_status: @order.order_status
        }, status: :not_found
      end

      render json: {
        pin_verification: {
          id: pin_verification.id,
          pin_code: pin_verification.pin_code, # Always show actual PIN to seller
          status: pin_verification.status,
          expires_at: pin_verification.expires_at,
          verified_at: pin_verification.verified_at,
          order_number: @order.order_number,
          buyer_name: @order.buyer.name,
          time_remaining: pin_verification.expires_at ? [pin_verification.expires_at - Time.current, 0].max.to_i : 0,
          is_active: pin_verification.active?
        },
        order_details: {
          id: @order.id,
          order_number: @order.order_number,
          buyer_name: @order.buyer.name,
          total_amount: @order.total_amount,
          items: @order.order_items.map do |item|
            {
              name: item.item.name,
              quantity: item.quantity,
              price: item.unit_price
            }
          end
        }
      }, status: :ok
    end
      # POST /api/v1/orders/:order_id/cancel_pin
      def cancel
        if @pin_verification.update(status: :cancelled)
          render json: {
            message: "PIN verification cancelled",
            pin_verification: serialize_pin_verification(@pin_verification)
          }, status: :ok
        else
          render json: { error: "Failed to cancel PIN verification" }, status: :unprocessable_entity
        end
      end
   # GET /api/v1/orders/:order_id/transaction_summary
     def transaction_summary
  pin_verification = @order.pin_verifications.last
  
  unless pin_verification
    return render json: { 
      error: "No PIN verification found for this order",
      order_status: @order.order_status
    }, status: :not_found
  end

  # Ensure order status consistency
  if pin_verification.verified? && @order.order_status != 'completed'
    @order.update!(order_status: 'completed', completed_at: Time.current)
  end

  render json: {
    transaction_summary: build_ui_data(pin_verification),
    order_status: @order.order_status,
    pin_verification_status: pin_verification.status,
    is_pin_active: pin_verification.active?,
    can_verify: pin_verification.active? && current_user.id == @order.buyer_id,
    can_see_pin: pin_verification.active? && current_user.id == pin_verification.seller_id
  }, status: :ok
end
      private

def build_ui_data(pin_verification)
  order = pin_verification.order
  order_item = order.order_items.first
  item = order_item&.item
  
  # Determine if current user should see the actual PIN
  current_user_can_see_pin = current_user.id == pin_verification.seller_id || 
                            (pin_verification.verified? && current_user.id == pin_verification.buyer_id)
  
  {
    # Product Information
    product_details: {
      image: item&.image_url.presence || item&.images&.first&.url || "/images/default-thumbnail.jpg",
      name: item&.name || "Item",
      description: item&.description || "Product from #{order.shop.name}",
      quantity: order_item&.quantity || 1,
      price_per_unit: order_item&.unit_price || order.total_amount
    },
    
    # Transaction Information
    transaction_details: {
      order_number: order.order_number,
      transaction_id: "TXN-#{pin_verification.id}",
      total_amount: order.total_amount,
      currency: "ZAR",
      payment_status: order.payment_status,
      order_status: order.order_status
    },
    
    # Collection Information
    collection_details: {
      pin_code: current_user_can_see_pin ? pin_verification.pin_code : '******',
      status: pin_verification.status,
      generated_at: pin_verification.created_at,
      expires_at: pin_verification.expires_at,
      verified_at: pin_verification.verified_at,
      time_remaining: pin_verification.expires_at ? [pin_verification.expires_at - Time.current, 0].max.to_i : 0
    },
    
    # Party Information
    parties: {
      buyer: {
        id: order.buyer.id,
        name: order.buyer.name,
        email: order.buyer.email,
        mobile: order.buyer.mobile
      },
      seller: {
        id: order.shop.user.id,
        name: order.shop.user.name,
        shop_name: order.shop.name,
        email: order.shop.user.email
      }
    },
    
    # UI Display Elements
    display: {
      status_badge: get_status_badge(pin_verification),
      status_message: get_status_message(pin_verification),
      status_color: get_status_color(pin_verification),
      show_pin: pin_verification.active? && current_user.id == pin_verification.seller_id,
      show_verify_button: pin_verification.active? && current_user.id == pin_verification.buyer_id,
      show_resend_button: pin_verification.active? && current_user.id == pin_verification.seller_id,
      current_user_role: current_user.id == pin_verification.buyer_id ? 'buyer' : 'seller'
    }
  }
end

def get_status_badge(pin_verification)
  case pin_verification.status
  when 'pending', 'active' then '🔢 PIN Active'
  when 'verified' then '✅ Collection Verified'
  when 'expired' then '⏰ PIN Expired'
  when 'cancelled' then '❌ Verification Cancelled'
  else '📋 Pending'
  end
end

def get_status_message(pin_verification)
  case pin_verification.status
  when 'pending', 'active'
    if pin_verification.active?
      "PIN is active. Expires at #{pin_verification.expires_at.strftime('%H:%M')}"
    else
      "PIN #{pin_verification.pin_code} is active. Expires at #{pin_verification.expires_at.strftime('%H:%M')}"
    end
  when 'verified'
    "Collection verified with PIN at #{pin_verification.verified_at.strftime('%H:%M')}"
  when 'expired'
    "PIN expired at #{pin_verification.expires_at.strftime('%H:%M')}"
  when 'cancelled'
    "PIN verification was cancelled"
  else
    "Waiting for PIN generation"
  end
end

def get_status_color(pin_verification)
  case pin_verification.status
  when 'pending', 'active' then 'blue'
  when 'verified' then 'green'
  when 'expired', 'cancelled' then 'red'
  else 'gray'
  end
end

     

      def authorize_order_access
        unless @order.buyer_id == current_user.id || @order.shop.user_id == current_user.id
          render json: { error: 'Access denied' }, status: :forbidden
        end
      end

      def send_pin_to_seller(pin_verification)
        seller = pin_verification.seller
        
        # Create notification for seller
        notification = Notification.create!(
          user: seller,
          title: "Collection PIN for Order ##{pin_verification.order.order_number}",
          message: "PIN: #{pin_verification.pin_code}. Expires at #{pin_verification.expires_at.strftime('%H:%M')}",
          notifiable: pin_verification,
          notification_type: 'pin_verification'
        )

        # Send FCM notification
        if seller.firebase_token.present?
          FirebaseNotificationService.deliver_later(notification)
        end

        # Also send via chat as a backup
        chat_room = ChatRoom.find_by(order: pin_verification.order)
        if chat_room
          ChatMessage.create!(
            chat_room: chat_room,
            sender: pin_verification.buyer,
            content: "Collection PIN: #{pin_verification.pin_code} (Expires: #{pin_verification.expires_at.strftime('%H:%M')})",
            message_type: :system
          )
        end
      end

      def send_verification_notifications(pin_verification, success)
        message = success ? 
          "Collection verified successfully for Order ##{pin_verification.order.order_number}" :
          "Failed PIN attempt for Order ##{pin_verification.order.order_number}"

        # Notify both buyer and seller
        [pin_verification.buyer, pin_verification.seller].each do |user|
          notification = Notification.create!(
            user: user,
            title: success ? "Collection Verified" : "PIN Verification Failed",
            message: message,
            notifiable: pin_verification,
            notification_type: success ? 'payment_received' : 'system_alert'
          )

          if user.firebase_token.present?
            FirebaseNotificationService.deliver_later(notification)
          end
        end

        # Also send via chat
        chat_room = ChatRoom.find_by(order: pin_verification.order)
        if chat_room
          ChatMessage.create!(
            chat_room: chat_room,
            sender: pin_verification.buyer,
            content: message,
            message_type: :system
          )
        end
      end
    def update_order_after_verification(order)
    # Check what status transitions are available for your Order model
    if order.may_mark_as_completed?
        order.mark_as_completed!
    elsif order.may_mark_as_delivered?
        order.mark_as_delivered!
    elsif order.may_mark_as_collected?
        order.mark_as_collected!
    else
        # Fallback - just update the status directly
        order.update!(order_status: 'completed', completed_at: Time.current)
    end
    
    # Also update any inventory/reserved quantities
    update_inventory_after_completion(order)
    end
    def update_inventory_after_completion(order)
  order.order_items.each do |order_item|
    item = order_item.item
    # Reduce reserved quantity and actual quantity
    item.with_lock do
      new_reserved = [item.reserved - order_item.quantity, 0].max
      new_quantity = [item.quantity - order_item.quantity, 0].max
      
      item.update!(
        reserved: new_reserved,
        quantity: new_quantity
      )
    end
  end
end
  def serialize_pin_verification(pin_verification)
  # Determine PIN visibility
  show_pin = if current_user.id == pin_verification.seller_id
               true  # Seller always sees PIN
             elsif current_user.id == pin_verification.buyer_id
               pin_verification.verified?  # Buyer only sees after verification
             else
               false  # Other users never see PIN
             end

  {
    id: pin_verification.id,
    pin_code: show_pin ? pin_verification.pin_code : '******',
    status: pin_verification.status,
    expires_at: pin_verification.expires_at,
    verified_at: pin_verification.verified_at,
    order_id: pin_verification.order_id,
    buyer_id: pin_verification.buyer_id,
    seller_id: pin_verification.seller_id,
    is_active: pin_verification.active?,
    time_remaining: pin_verification.expires_at ? [pin_verification.expires_at - Time.current, 0].max.to_i : 0,
    can_see_pin: show_pin,
    user_role: current_user.id == pin_verification.buyer_id ? 'buyer' : 'seller'
  }
 end
    end
  end
end