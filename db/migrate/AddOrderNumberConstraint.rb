class AddOrderNumberConstraint < ActiveRecord::Migration[7.0]
  def change
    change_column_null :orders, :order_number, false
    add_index :orders, :order_number, unique: true
  end
end
