# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    chat_room = ChatRoom.find_by(room_id: params[:room_id])
    if chat_room && authorized?(chat_room)
      stream_for chat_room
      broadcast_presence
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def receive(data)
    chat_room = ChatRoom.find_by(room_id: params[:room_id])
    return unless chat_room && authorized?(chat_room)

    ChatMessage.create!(
      chat_room: chat_room,
      sender: current_user,
      content: data['content'],
      message_type: 'text'
    )
  end

  private

  def authorized?(chat_room)
    chat_room.participants.include?(current_user)
  end

  def broadcast_presence
    chat_room = ChatRoom.find_by(room_id: params[:room_id])
    ChatChannel.broadcast_to(
      chat_room,
      {
        type: 'user_joined',
        user_id: current_user.id,
        user_name: current_user.name,
        timestamp: Time.current.iso8601
      }
    )
  end
end