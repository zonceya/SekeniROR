module Api
  module V1
    class ChatMessagesController < Api::V1::BaseController
      before_action :authenticate_request!
      before_action :set_chat_room
      before_action :authorize_chat_access

      def index
        messages = @chat_room.chat_messages.order(created_at: :asc)
        
        # Mark messages as read
        @chat_room.chat_messages
                 .where.not(sender: current_user)
                 .where(read: false)
                 .update_all(read: true, updated_at: Time.current)

        render json: {
          messages: messages.map { |msg| serialize_message(msg) }
        }, status: :ok
      end

      def create
        message = @chat_room.chat_messages.new(
          sender: current_user,
          content: params[:content],
          message_type: params[:message_type] || 'text'
        )

        if message.save
          render json: {
            message: serialize_message(message)
          }, status: :created
        else
          render json: { error: message.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def mark_as_read
        @chat_room.chat_messages
                 .where.not(sender: current_user)
                 .where(read: false)
                 .update_all(read: true, updated_at: Time.current)

        render json: { success: true }, status: :ok
      end

      private

      def set_chat_room
        @chat_room = ChatRoom.find_by(room_id: params[:chat_room_id])
        render json: { error: 'Chat room not found' }, status: :not_found unless @chat_room
      end

      def authorize_chat_access
        unless @chat_room.participants.include?(current_user)
          render json: { error: 'Access denied to this chat room' }, status: :forbidden
        end
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