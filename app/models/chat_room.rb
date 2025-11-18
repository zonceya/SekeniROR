class ChatRoom < ApplicationRecord
  belongs_to :order
  belongs_to :buyer, class_name: 'User'
  belongs_to :seller, class_name: 'User'
  has_many :chat_messages, dependent: :destroy

  validates :order_id, uniqueness: true

  before_create :generate_room_id

  def participants
    [buyer, seller]
  end

  def other_participant(current_user)
    current_user == buyer ? seller : buyer
  end

  private

  def generate_room_id
    self.room_id ||= "chat_#{SecureRandom.hex(10)}"
  end
end