class ChangeHoldsOrderIdNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :holds, :order_id, true
  end
end
