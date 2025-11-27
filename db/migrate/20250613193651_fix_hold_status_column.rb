class FixHoldStatusColumn < ActiveRecord::Migration[8.0]
  def change
    # First update all NULL values to default
    execute("UPDATE holds SET status = 0 WHERE status IS NULL")
    
    # Then change the column constraints
    change_column_null :holds, :status, false
    change_column_default :holds, :status, 0
  end
end
