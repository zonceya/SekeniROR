# db/migrate/20251107000000_create_pin_verifications.rb
class CreatePinVerifications < ActiveRecord::Migration[7.0]
  def change
    create_table :pin_verifications do |t|
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.references :seller, null: false, foreign_key: { to_table: :users }
      t.string :pin_code, null: false
      t.string :status, null: false, default: 'pending'
      t.datetime :verified_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :pin_verifications, [:order_id, :status]
    add_index :pin_verifications, :pin_code
  end
end