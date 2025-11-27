class FinalFixHoldStatus < ActiveRecord::Migration[8.0]
   def change
    # Step 1: Allow NULL temporarily
    change_column_null :holds, :status, true

    # Step 2: Update all NULLs to default
    reversible do |dir|
      dir.up { execute("UPDATE holds SET status = 0 WHERE status IS NULL") }
    end

    # Step 3: Set proper constraints
    change_column_null :holds, :status, false
    change_column_default :holds, :status, 0
  end
end
