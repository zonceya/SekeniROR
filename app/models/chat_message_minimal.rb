class ChatMessage < ApplicationRecord
  belongs_to :chat_room
  belongs_to :sender, class_name: 'User'
  validates :content, presence: true
end
