class CreateFlaggedPayments < ActiveRecord::Migration[8.0]
  def change
    create_table :flagged_payments, id: :uuid do |t|
      t.references :order, null: true, foreign_key: true, type: :uuid
      t.decimal :expected_amount, precision: 10, scale: 2
      t.decimal :received_amount, precision: 10, scale: 2
      t.string :reference
      t.string :bank
      t.string :status

      t.timestamps
    end
  end
end