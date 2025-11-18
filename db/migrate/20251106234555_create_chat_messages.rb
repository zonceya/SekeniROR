class CreateChatMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_messages do |t|
      t.references :chat_room, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :content, null: false
      t.string :message_type, default: 'text'
      t.boolean :read, default: false
      t.string :attachment_url

      t.timestamps
    end

    add_index :chat_messages, [:chat_room_id, :created_at]
  end
end