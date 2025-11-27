class CreateWalletTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :wallet_transactions do |t|
      t.bigint :digital_wallet_id, null: false
      t.uuid :order_id
      t.bigint :transfer_request_id
      
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.decimal :net_amount, precision: 10, scale: 2, null: false
      t.decimal :service_fee, precision: 10, scale: 2, default: 0.0
      t.decimal :insurance_fee, precision: 10, scale: 2, default: 0.0
      
      t.string :transaction_type, null: false
      t.string :status, null: false, default: 'pending'
      t.string :transaction_source, null: false
      t.string :description
      t.jsonb :metadata

      t.timestamps
    end

    add_index :wallet_transactions, :digital_wallet_id
    add_index :wallet_transactions, :order_id
    add_index :wallet_transactions, :transfer_request_id
    add_index :wallet_transactions, :status
    add_index :wallet_transactions, :transaction_type
    add_index :wallet_transactions, :transaction_source
    add_index :wallet_transactions, :created_at
  end
end