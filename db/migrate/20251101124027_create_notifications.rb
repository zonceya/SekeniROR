class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :notifiable, polymorphic: true, null: false
      t.string :title
      t.string :message
      t.string :notification_type
      t.string :status
      t.boolean :read
      t.datetime :delivered_at
      t.boolean :firebase_sent
      t.text :firebase_response

      t.timestamps
    end
  end
end
