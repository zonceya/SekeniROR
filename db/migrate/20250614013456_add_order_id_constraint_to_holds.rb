class AddOrderIdConstraintToHolds < ActiveRecord::Migration[7.0]
  def change
    change_column_null :holds, :order_id, false, if: "status = 'completed'"
    add_check_constraint :holds, 
      "(status != 'completed') OR (order_id IS NOT NULL)",
      name: 'check_completed_holds_have_order'
  end
end