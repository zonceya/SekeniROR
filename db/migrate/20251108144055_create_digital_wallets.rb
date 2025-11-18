class CreateDigitalWallets < ActiveRecord::Migration[7.0]
  def change
    create_table :digital_wallets do |t|
      t.bigint :user_id, null: false
      t.string :wallet_number, null: false
      t.decimal :current_balance, precision: 10, scale: 2, default: 0.0
      t.decimal :pending_balance, precision: 10, scale: 2, default: 0.0

      t.timestamps
    end

    add_index :digital_wallets, :wallet_number, unique: true
    add_index :digital_wallets, :user_id, unique: true
    # We'll add foreign key constraint manually later if needed
    # add_foreign_key :digital_wallets, :users
  end
end
