class SetDefaultStatusForHolds < ActiveRecord::Migration[8.0]
  def change
   change_column_default :holds, :status, from: nil, to: "awaiting_payment"
    change_column_null :holds, :status, false, "awaiting_payment"
  end
end
