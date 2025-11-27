# db/migrate/20251114194049_create_refund_system.rb
class CreateRefundSystem < ActiveRecord::Migration[8.0]
  def change
    # Create disputes table first (no dependencies)
    create_table :disputes, id: :uuid do |t|
      t.uuid :order_id, null: false
      t.bigint :raised_by_id, null: false  # Changed to bigint to match users.id
      t.string :dispute_reference, null: false
      t.string :status, null: false
      t.string :reason, null: false
      t.text :description
      t.json :evidence_photos
      t.text :admin_notes
      t.datetime :resolved_at
      t.bigint :resolved_by_id  # Changed to bigint
      t.timestamps
    end

    # Create seller_strikes table
    create_table :seller_strikes, id: :uuid do |t|
      t.bigint :seller_id, null: false  # Changed to bigint to match users.id
      t.string :reason, null: false
      t.string :severity, null: false
      t.string :status, default: 'active'
      t.datetime :expires_at
      t.text :notes
      t.timestamps
    end

    # Create refunds table (depends on disputes)
    create_table :refunds, id: :uuid do |t|
      t.uuid :order_id, null: false
      t.uuid :dispute_id
      t.uuid :wallet_transaction_id
      t.bigint :processed_by_id  # Changed to bigint to match users.id
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :status, null: false
      t.string :reason, null: false
      t.string :refund_type, null: false
      t.text :notes
      t.datetime :processed_at
      t.datetime :estimated_completion
      t.timestamps
    end

    # Add indexes
    add_index :disputes, :dispute_reference, unique: true
    add_index :disputes, :order_id
    add_index :disputes, :raised_by_id
    add_index :refunds, :order_id
    add_index :refunds, :dispute_id
    add_index :seller_strikes, :seller_id

    # Add foreign keys
    add_foreign_key :disputes, :orders, column: :order_id, type: :uuid
    add_foreign_key :refunds, :orders, column: :order_id, type: :uuid
    add_foreign_key :refunds, :disputes, column: :dispute_id, type: :uuid
    
    add_foreign_key :seller_strikes, :users, column: :seller_id, type: :uuid
  end
end