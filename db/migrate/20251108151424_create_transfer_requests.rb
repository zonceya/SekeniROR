class CreateTransferRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :transfer_requests do |t|
      t.bigint :digital_wallet_id, null: false
      t.bigint :bank_account_id, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :reference, null: false
      t.string :status, null: false, default: 'pending'
      t.text :admin_notes
      t.datetime :processed_at

      t.timestamps
    end

    add_index :transfer_requests, :digital_wallet_id
    add_index :transfer_requests, :bank_account_id
    add_index :transfer_requests, :reference, unique: true
    add_index :transfer_requests, :status
  end
end