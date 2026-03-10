# db/migrate/xxxxxx_create_user_item_views.rb
class CreateUserItemViews < ActiveRecord::Migration[8.0]
  def change
    create_table :user_item_views do |t|
      t.references :user, foreign_key: true, null: true
      t.uuid :item_id, null: false
      t.integer :school_id, null: false
      t.string :source
      t.string :session_id
      t.integer :view_count, default: 1
      t.string :device_type
      t.string :referrer
      t.timestamps
    end

    add_foreign_key :user_item_views, :items
    add_index :user_item_views, [:user_id, :item_id], name: 'idx_user_item_views_user_item'
    add_index :user_item_views, [:school_id, :created_at], name: 'idx_user_item_views_school_recent'
    add_index :user_item_views, [:item_id, :view_count], name: 'idx_user_item_views_item_popular'
    add_index :user_item_views, :created_at
  end
end