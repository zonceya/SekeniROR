class CreateHolds < ActiveRecord::Migration[7.0]
  def change
    create_table :holds do |t|
      t.references :item, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :bigint  # Match users table
      t.references :order, foreign_key: true, type: :uuid
      t.integer :quantity, null: false
      t.datetime :expires_at, null: false
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :holds, :status
    add_index :holds, :expires_at
  end
end