module Api
  module V1
    class ChatRoomsController < Api::V1::BaseController
      before_action :authenticate_request!

      def index
        chat_rooms = current_user.chat_rooms.includes(:buyer, :seller, :order, :chat_messages)
        
        render json: {
          chat_rooms: chat_rooms.map { |room| serialize_chat_room(room) }
        }, status: :ok
      end

      def show
        chat_room = ChatRoom.includes(:chat_messages).find_by(room_id: params[:id])
        
        if chat_room && chat_room.participants.include?(current_user)
          render json: {
            chat_room: serialize_chat_room(chat_room),
            messages: chat_room.chat_messages.order(created_at: :asc).map { |msg| serialize_message(msg) }
          }, status: :ok
        else
          render json: { error: 'Chat room not found or access denied' }, status: :not_found
        end
      end

      def create
        order = Order.find(params[:order_id])
        
        # Check if user is participant in the order
        unless order.buyer_id == current_user.id || order.shop.user_id == current_user.id
          return render json: { error: 'Access denied' }, status: :forbidden
        end

        chat_room = ChatRoom.find_or_create_by(order: order) do |room|
          room.buyer = order.buyer
          room.seller = order.shop.user
          room.room_id = "order_#{order.id}_#{SecureRandom.hex(4)}"
        end

        render json: {
          chat_room: serialize_chat_room(chat_room)
        }, status: :ok
      end

      private

     def serialize_chat_room(room)
    other_user = room.other_participant(current_user)
    last_message = room.chat_messages.last
  
        {
            id: room.id,
            room_id: room.room_id,
            order_id: room.order_id,
            order_number: room.order.order_number,
            other_user: {
            id: other_user.id,
            name: other_user.name,
            profile_image: other_user.profile&.profile_picture || 'default.png'  # FIXED THIS LINE
            },
            last_message: last_message ? serialize_message(last_message) : nil,
            unread_count: room.chat_messages.where.not(sender: current_user).where(read: false).count,
            created_at: room.created_at.iso8601
        }
    end

      def serialize_message(message)
        {
          id: message.id,
          content: message.content,
          sender_id: message.sender_id,
          sender_name: message.sender.name,
          message_type: message.message_type,
          created_at: message.created_at.iso8601,
          read: message.read
        }
      end
    end
  end
end