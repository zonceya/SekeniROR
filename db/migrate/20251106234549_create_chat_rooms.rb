class CreateChatRooms < ActiveRecord::Migration[7.0]
  def change
    # Only create table if it doesn't exist
    return if table_exists?(:chat_rooms)

    create_table :chat_rooms do |t|
      t.string :room_id, null: false
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.references :seller, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    # Only add indexes if they don't exist
    unless index_exists?(:chat_rooms, :room_id)
      add_index :chat_rooms, :room_id, unique: true
    end
    
    unless index_exists?(:chat_rooms, :order_id)
      add_index :chat_rooms, :order_id, unique: true
    end
  end
end