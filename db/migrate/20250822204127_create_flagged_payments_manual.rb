# db/migrate/20250822195619_create_flagged_payments_manual.rb
class CreateFlaggedPaymentsManual < ActiveRecord::Migration[8.0]
  def change
    create_table :flagged_payments, id: :uuid do |t|
      t.uuid :order_id, null: true
      t.decimal :expected_amount, precision: 10, scale: 2
      t.decimal :received_amount, precision: 10, scale: 2
      t.string :reference
      t.string :bank
      t.string :status

      t.timestamps
    end

    # Add foreign key manually if needed
    add_foreign_key :flagged_payments, :orders, column: :order_id, type: :uuid
  end
end