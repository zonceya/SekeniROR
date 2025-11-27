# db/migrate/20251028190000_create_order_transactions.rb
class CreateOrderTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :order_transactions do |t|
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :txn_status, null: false
      t.string :payment_method
      t.string :bank_ref_num
      t.string :bank
      t.datetime :txn_time
      
      t.timestamps
    end
    
    add_index :order_transactions, :txn_status
    add_index :order_transactions, :bank_ref_num
  end
end