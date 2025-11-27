class FixHoldStatusDefault < ActiveRecord::Migration[8.0]
  def up
    # Step 1: Update all NULL values to the default (0)
    execute("UPDATE holds SET status = 0 WHERE status IS NULL")
    
    # Step 2: Change the column to not allow NULL
    change_column_null :holds, :status, false
    
    # Step 3: Ensure default value is set
    change_column_default :holds, :status, 0
  end

  def down
    # For rollback safety
    change_column_null :holds, :status, true
    change_column_default :holds, :status, nil
  end
end
