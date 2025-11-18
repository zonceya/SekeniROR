class CreateBankAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :bank_accounts do |t|
      t.bigint :digital_wallet_id, null: false
      t.string :account_holder_name, null: false
      t.string :bank_name, null: false
      t.string :account_number, null: false
      t.string :branch_code, null: false
      t.string :account_type, default: 'savings'

      t.timestamps
    end

    add_index :bank_accounts, :digital_wallet_id
    add_index :bank_accounts, [:bank_name, :account_number, :branch_code], unique: true, name: 'index_bank_accounts_unique'
  end
end